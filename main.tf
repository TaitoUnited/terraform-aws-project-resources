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

locals {

  secret_resource_path = var.secret_resource_path != "" ? var.secret_resource_path : "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.zone_name}/${var.namespace}"

  secret_name_path = var.secret_name_path != "" ? var.secret_name_path : "/${var.zone_name}/${var.namespace}"

  serviceAccounts = (
    var.create_service_accounts && coalesce(var.resources.serviceAccounts, null) != null
    ? coalesce(var.resources.serviceAccounts, [])
    : []
  )

  ingress = defaults(var.resources.ingress, { enabled: false })

  domains = coalesce(var.resources.ingress.domains, [])

  mainDomains = [
    for domain in local.domains:
    join(".",
      slice(
        split(".", domain.name),
        length(split(".", domain.name)) > 2 ? 1 : 0,
        length(split(".", domain.name))
      )
    )
  ]

  services = (
    coalesce(var.resources.services, null) != null
    ? coalesce(var.resources.services, {})
    : {}
  )

  servicesById = {
    for id, service in local.services:
    id => merge(service, { id: id })
  }

  uptimeEnabled = coalesce(var.resources.uptimeEnabled, true)
  uptimeTargetsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_uptime_checks && local.uptimeEnabled && coalesce(service.uptimePath, null) != null
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
    if var.create_function_permissions && service.type == "function" && coalesce(service.awsPolicy, null) != null
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

  topicsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_topics && service.type == "topic"
  }

  topicPublishers = flatten([
    for service in local.topicsById: [
      for user in coalesce(service.publishers, []):
      { topicId: service.id, userId: user.id }
    ]
  ])

  topicSubscribers = flatten([
    for service in local.topicsById: [
      for user in coalesce(service.subscribers, []):
      { topicId: service.id, userId: user.id }
    ]
  ])

  bucketsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_storage_buckets && service.type == "bucket"
  }

  bucketAdmins = flatten([
    for service in local.bucketsById: [
      for user in coalesce(
        service.admins != null
        ? service.admins
        : [],
        []
      ):
      { bucketId: service.id, userId: user.id }
    ]
  ])

  bucketObjectAdmins = flatten([
    for service in local.bucketsById: [
      for user in coalesce(
        service.objectAdmins != null
        ? service.objectAdmins
        : [],
        []
      ):
      { bucketId: service.id, userId: user.id }
    ]
  ])

  bucketObjectViewers = flatten([
    for service in local.bucketsById: [
      for user in coalesce(
        service.objectViewers != null
        ? service.objectViewers
        : [],
        []
      ):
      { bucketId: service.id, userId: user.id }
    ]
  ])

  containerRegistryTargets = (
    var.create_container_image_repositories
      ? distinct(concat(var.additional_container_images, keys({
          for name, service in local.servicesById:
          name => service
          if contains(var.container_image_target_types, service.type)
        })))
      : []
  )

  gatewayFunctionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "function" && coalesce(service.path, "") != ""
  }

  gatewayStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "static"
  }

  gatewayRootStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && coalesce(service.path, "") == "/"
  }

  gatewayChildStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && coalesce(service.path, "") != "/"
  }

  gatewayEnabled = length(concat(
    values(local.gatewayFunctionsById),
    values(local.gatewayStaticContentsById),
  )) > 0

}
