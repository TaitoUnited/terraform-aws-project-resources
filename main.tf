/**
 * Copyright 2021 Taito United
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "aws" {
  region  = var.region
  profile = var.user_profile
}

provider "aws" {
  alias   = "useast1"
  region  = "us-east-1"
  profile = var.user_profile
}

locals {
  # Set defaults
  resources = defaults(var.resources, {
    backupEnabled = false
    uptimeEnabled = false

    ingress = {
      enabled = false
      class = "cloudfront"
      createMainDomain = false
    }
  })

  tags = {
    project = var.project
    env = var.env
  }

  secret_resource_path = var.secret_resource_path != "" ? var.secret_resource_path : "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.zone_name}/${var.namespace}"

  secret_name_path = var.secret_name_path != "" ? var.secret_name_path : "/${var.zone_name}/${var.namespace}"

  serviceAccounts = (
    var.create_service_accounts
    ? coalesce(local.resources.serviceAccounts, [])
    : []
  )

  ingress = local.resources.ingress

  domains = [
    for domain in coalesce(local.ingress.domains, []):
    merge(domain, {
      mainDomain = join(".",
        slice(
          split(".", domain.name),
          length(split(".", domain.name)) > 2 ? 1 : 0,
          length(split(".", domain.name))
        )
      )
    })
  ]

  services = coalesce(local.resources.services, {})

  servicesById = {
    for id, service in local.services:
    id => merge(service, { id: id })
    if service.enabled == null || service.enabled == true
  }

  uptimeTargetsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_uptime_checks && local.resources.uptimeEnabled && service.uptimePath != null
  }

  containersById = {
    for name, service in local.servicesById:
    name => service
    if var.create_containers && service.type == "container"
  }

  functionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_functions && service.type == "function"
  }

  functionsForPermissionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_function_permissions && service.type == "function"
  }

  functionsWithPolicyById = {
    for name, service in local.servicesById:
    name => service
    if var.create_function_permissions && service.type == "function" && service.awsPolicy != null
  }

  functionCronJobsById = {
    for cronJob in flatten([
      for id, function in local.functionsById: [
        for cronJob in coalesce(function.cronJobs, []):
        merge(cronJob, {
          id = "${id}-${cronJob.name}"
          function = function
        })
      ]
    ]): cronJob.id => cronJob
  }

  functionSourcesById = {
    for source in flatten([
      for id, function in local.functionsById: [
        for source in coalesce(function.sources, []):
        merge(source, {
          id = "${id}-${source.name}"
          function = function
        })
      ]
    ]): source.id => source
  }

  functionSqsSourcesById = {
    for id, source in local.functionSourcesById:
    id => source
    if source.type == "queue"
  }

  deadLetterQueuesByName = {
    for name, service in local.functionsById:
    service.deadLetterQueue => {
      name = service.deadLetterQueue
    }
    if service.deadLetterQueue != null
  }

  deadLetterTopicsByName = {
    for name, service in local.functionsById:
    service.deadLetterTopic => {
      name = service.deadLetterTopic
    }
    if service.deadLetterTopic != null
  }

  databasesById = {
    for name, service in local.servicesById:
    name => service
    if var.create_databases && (service.type == "pg" || service.type == "mysql")
  }

  redisDatabasesById = {
    for name, service in local.servicesById:
    name => service
    if var.create_in_memory_databases && (service.type == "redis")
  }

  queuesById = {
    for name, service in local.servicesById:
    name => service
    if var.create_queues && service.type == "queue"
  }

  topicsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_topics && service.type == "topic"
  }

  topicPublishers = flatten([
    for service in local.topicsById: [
      for user in coalesce(service.publishers, []):
      { key: "${service.id}-${user.id}", topicId: service.id, userId: user.id }
    ]
  ])

  topicSubscribers = flatten([
    for service in local.topicsById: [
      for user in coalesce(service.subscribers, []):
      { key: "${service.id}-${user.id}", topicId: service.id, userId: user.id }
    ]
  ])

  bucketsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_storage_buckets && service.type == "bucket"
  }

  bucketAdmins = flatten([
    for service in local.bucketsById: [
      for user in coalesce(service.admins, []):
      { key: "${service.id}-${user.id}", bucketId: service.id, userId: user.id }
    ]
  ])

  bucketObjectAdmins = flatten([
    for service in local.bucketsById: [
      for user in coalesce(service.objectAdmins, []):
      { key: "${service.id}-${user.id}", bucketId: service.id, userId: user.id }
    ]
  ])

  bucketObjectViewers = flatten([
    for service in local.bucketsById: [
      for user in coalesce(service.objectViewers, []):
      { key: "${service.id}-${user.id}", bucketId: service.id, userId: user.id }
    ]
  ])

  containerRegistryTargets = (
    var.create_container_image_repositories
      ? distinct(concat(var.additional_container_images, keys({
          for name, service in local.servicesById:
          name => service
          if contains(var.container_image_target_types, service.type != null && service.image == null ? service.type : "no-match")
        })))
      : []
  )

  containerRegistryBuilderTargets = (
    var.create_container_image_repositories
      ? distinct(concat(local.containerRegistryTargets, keys({
          for name, service in local.servicesById:
          name => service
          if contains(var.container_image_builder_target_types, service.type != null && service.image == null ? service.type : "no-match")
        })))
      : []
  )

  cloudfrontStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && local.ingress.class == "cloudfront" && service.type == "static"
  }

  cloudfrontFunctionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "function" && service.path != null
  }

  cloudfrontFunctionsByReversePathLength = {
    for name, service in local.cloudfrontFunctionsById:
    99 - length(service.path) => service
  }

  gatewayFunctionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "function" && service.path != null
  }

  gatewayFunctionsLevel0ByPath = {
    for id, service in local.gatewayFunctionsById:
    service.path => service
    if length(split("/", service.path)) == 2
  }

  gatewayFunctionsLevel1ByPath = {
    for id, service in local.gatewayFunctionsById:
    service.path => service
    if length(split("/", service.path)) == 3
  }

  gatewayStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && local.ingress.class == "gateway" && service.type == "static"
  }

  gatewayRootStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && local.ingress.class == "gateway" && service.path != null && coalesce(service.path, "") == "/"
  }

  gatewayChildStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && local.ingress.class == "gateway" && service.path != null && coalesce(service.path, "") != "/"
  }

  gatewayEnabled = length(concat(
    values(local.gatewayFunctionsById),
    values(local.gatewayStaticContentsById),
  )) > 0

  gatewayDomainEnabled = local.gatewayEnabled && local.ingress.class == "gateway"

  cloudfrontEnabled = var.create_ingress && local.ingress.enabled && local.ingress.class == "cloudfront"
}
