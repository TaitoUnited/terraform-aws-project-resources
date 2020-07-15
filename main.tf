/**
 * Copyright 2020 Taito United
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

  gateway_asset_reader = var.gateway_asset_reader != "" ? var.gateway_asset_reader :  "arn:aws:iam::${var.account_id}:role/${var.zone_name}-gateway"

  secret_resource_path = var.secret_resource_path != "" ? var.secret_resource_path : "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.zone_name}/${var.namespace}"

  secret_name_path = var.secret_name_path != "" ? var.secret_name_path : "/${var.zone_name}/${var.namespace}"

  serviceAccounts = var.create_service_accounts ? try(
    var.variables.serviceAccounts != null
    ? var.variables.serviceAccounts
    : [],
    []
  ) : []

  ingress = try(var.variables.ingress, { enabled: false })

  domains = try(var.variables.ingress.domains, [])

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

  servicesById = {
    for id, service in var.variables.services:
    id => merge(service, { id: id })
  }

  uptimeEnabled = try(var.variables.uptimeEnabled, true)
  uptimeTargetsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_uptime_checks && local.uptimeEnabled && try(service.uptimePath, null) != null
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
    if var.create_function_permissions && service.type == "function" && try(service.awsPolicy, null) != null
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
      for user in try(service.publishers, []):
      { topicId: service.id, userId: user.id }
    ]
  ])

  topicSubscribers = flatten([
    for service in local.topicsById: [
      for user in try(service.subscribers, []):
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
      for user in try(
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
      for user in try(
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
      for user in try(
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

  gatewayFunctions = {
    for name, service in local.servicesById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.type == "function" && try(service.path, "") != ""
  }

  gatewayStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.type == "static"
  }

  gatewayRootStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.path != null && try(service.path, "") == "/"
  }

  gatewayChildStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.path != null && try(service.path, "") != "/"
  }

  gatewayEnabled = length(concat(
    values(local.gatewayFunctions),
    values(local.gatewayStaticContentsById),
  )) > 0

}
