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

# Create flags

variable "create_cicd_service_account" {
  type        = bool
  default     = false
  description = "If true, a CI/CD user account is created."
}

variable "create_cicd_role" {
  type        = bool
  default     = false
  description = "If true, CI/CD role is created (required for AWS CodeBuild)."
}

variable "create_domain" {
  type        = bool
  default     = false
  description = "If true, a DNS setup is created for each main domain."
}

variable "create_domain_certificate" {
  type        = bool
  default     = false
  description = "If true, a domain certificate is created for each domain."
}

# NOTE: NOT SUPPORTED BY THE AWS MODULE
# variable "create_build_trigger" {
#   type        = bool
#   default     = false
#   description = "If true, build trigger will be created."
# }

variable "create_storage_buckets" {
  type        = bool
  default     = false
  description = "If true, storage buckets are created."
}

variable "create_databases" {
  type        = bool
  default     = false
  description = "If true, databases are created."
}

variable "create_in_memory_databases" {
  type        = bool
  default     = false
  description = "If true, in-memory databases are created."
}

variable "create_topics" {
  type        = bool
  default     = false
  description = "If true, topics are created."
}

variable "create_ingress" {
  type        = bool
  default     = false
  description = "If true, API Gateway is created."
}

variable "create_containers" {
  type        = bool
  default     = false
  description = "If true, containers are created."
}

variable "create_functions" {
  type        = bool
  default     = false
  description = "If true, functions are created."
}

variable "create_function_permissions" {
  type        = bool
  default     = false
  description = "If true, function permissions are created."
}

variable "create_service_accounts" {
  type        = bool
  default     = false
  description = "If true, service accounts are created."
}

# NOTE: NOT SUPPORTED BY THE AWS MODULE
# variable "create_service_account_roles" {
#   type        = bool
#   default     = false
#   description = "If true, service account IAM permissions are created. (TODO)"
# }

# NOTE: NOT SUPPORTED BY THE AWS MODULE
# variable "create_api_keys" {
#   type        = bool
#   default     = false
#   description = "If true, api keys are created. (TODO)"
# }

variable "create_uptime_checks" {
  type        = bool
  default     = false
  description = "If true, uptime check and alert is created for each service with uptime path set."
}

# NOTE: NOT SUPPORTED BY THE AWS MODULE
# variable "create_log_alert_metrics" {
#   type        = bool
#   default     = false
#   description = "If true, log metrics are created for all log alerts. (TODO)"
# }

# NOTE: NOT SUPPORTED BY THE AWS MODULE
# variable "create_log_alert_policies" {
#   type        = bool
#   default     = false
#   description = "If true, alert policies are created for log alerts (TODO)"
# }

variable "create_container_image_repositories" {
  type        = bool
  default     = false
  description = "If true, container image repositories are created."
}

# AWS provider

variable "account_id" {
  type = string
  description = "AWS account id."
}

variable "user_profile" {
  type        = string
  description = "AWS user profile that is used to create the resources."
}

variable "region" {
  type        = string
  description = "AWS region."
}

# Project

variable "zone_name" {
  type = string
  default = ""
  description = "Name of the zone (e.g. \"my-zone\"). It is required if secret_resource_path has not been set. "
}

variable "project" {
  type = string
  default = ""
  description = "Name of the project (e.g. \"my-project\")"
}

variable "namespace" {
  type = string
  default = ""
  description = "Namespace for the project environment (e.g. \"my-project-dev\"). Required if secret_resource_path has not been set"
}

variable "env" {
  type        = string
  description = "Environment (e.g. \"dev\")"
}

# Build info

variable "build_image_tag" {
  type = string
  default = "latest"
  description = "For example git commit hash (ddee8c8da71393b4b2ef95de507358abe54d7e78). Required if create_ingress or create_functions is true."
}

# Container image repositories

variable "container_image_repository_path" {
  type        = string
  default     = ""
  description = "Required if create_container_image_repositories is true."
}

variable "container_image_target_types" {
  type        = list(string)
  default     = [ "container" ]
  description = "Service types that require a container image repository."
}

variable "container_image_builder_target_types" {
  type        = list(string)
  default     = [ "static", "container", "function" ]
  description = "Service types that require a container image repository for the builder image that is used for caching and testing."
}

variable "additional_container_images" {
  type        = list(string)
  default     = []
  description = "Additional container image names (e.g. [ \"client\", \"server\" ]). Use this if not all services are defined in the YAML file."
}

# Network

variable "function_subnet_ids" {
  type    = list(string)
  default = []
  description = "Default subnet ids for functions. Required if create_functions is true."
}

variable "function_security_group_ids" {
  type    = list(string)
  default = []
  description = "Default security group ids for functions. Required if create_functions is true."
}

variable "elasticache_subnet_ids" {
  type    = list(string)
  default = []
  description = "Default subnet ids for elasticache. Required if create_in_memory_databases is true."
}

variable "elasticache_security_group_ids" {
  type    = list(string)
  default = []
  description = "Default security group ids for elasticache. Required if create_in_memory_databases is true."
}

# Permissions

variable "cicd_policies" {
  type    = list(string)
  default = []
  description = "Policy ARN:s attached to the CI/CD role. The policies should provide access to Kubernetes, assets bucket, functions bucket, secrets, etc."
}

variable "gateway_policies" {
  type    = list(string)
  default = []
  description = "Role used by API Gateway to read static assets from assets bucket."
}

# Secrets

variable "secret_resource_path" {
  type    = string
  default = ""
  description = "AWS Secret Manager resource path for secrets. If not set, the following is used by default: arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:/ZONE_NAME/NAMESPACE"
}

variable "secret_name_path" {
  type    = string
  default = ""
  description = "AWS Secret Manager name path for secrets. If not set, the following is used by default: /ZONE_NAME/NAMESPACE"
}

variable "cicd_secrets_path" {
  type    = string
  default = ""
  description = "AWS Secret Manager name path for CI/CD secrets."
}

# Buckets

variable "static_assets_bucket" {
  type    = string
  default = ""
  description = "Storage bucket for static assets (html, css, js). Required if create_ingress is true."
}

variable "static_assets_path" {
  type    = string
  default = ""
  description = "Storage bucket path for static assets (html, css, js). Required if create_ingress is true."
}

variable "functions_bucket" {
  type    = string
  default = ""
  description = "Storage bucket for function zip-packages. Required if create_functions is true."
}

variable "functions_path" {
  type    = string
  default = ""
  description = "Storage bucket path for function zip-packages. Required if create_functions is true."
}

variable "state_bucket" {
  type    = string
  description = "Storage bucket for terraform state. Required if create_cicd_service_account or create_cicd_role is true."
}

variable "state_path" {
  type    = string
  description = "Storage bucket path for terraform state. Required if create_cicd_service_account or create_cicd_role is true."
}

# Uptime settings

variable "uptime_channels" {
  type = list(string)
  default = []
  description = "SNS topics used to send alert notifications (e.g. \"arn:aws:sns:us-east-1:0123456789:my-zone-uptimez\")"
}

# Resources as a json/yaml

variable "resources" {
  type = object({
    backupEnabled = optional(bool)
    uptimeEnabled = optional(bool)

    # NOTE: NOT SUPPORTED BY THE AWS MODULE
    # alerts = optional(list(object({
    #   name = string
    #   type = string
    #   channels = list(string)
    #   rule = string
    # })))

    serviceAccounts = optional(list(object({
      id = string
      # NOTE: NOT SUPPORTED BY THE AWS MODULE
      # roles = list(string)
    })))

    # NOTE: NOT SUPPORTED BY THE AWS MODULE
    # apiKeys = optional(list(object({
    #   name = string
    #   services = list(string)
    #   origins = list(string)
    # })))

    ingress = optional(object({
      class = optional(string)
      enabled = optional(bool)
      createMainDomain = optional(bool)
      domains = list(object({
        name = string
        altDomains = list(object({
          name = string
        }))
      }))
    }))

    services = optional(map(object({
      type = string
      image = optional(string)
      machineType = optional(string)
      name = optional(string)
      location = optional(string)
      storageClass = optional(string)
      corsRules = optional(list(object({
        allowedOrigins = list(string)
        allowedMethods = optional(list(string))
        exposeHeaders = optional(list(string))
        allowedHeaders = optional(list(string))
        maxAgeSeconds = optional(number)
      })))
      queues = optional(list(object({
        name = string
        events = list(string)
      })))
      versioningEnabled = optional(bool)
      versioningRetainDays = optional(number)
      lockRetainDays = optional(number)
      transitionRetainDays = optional(number)
      transitionStorageClass = optional(string)
      autoDeletionRetainDays = optional(number)
      replicationBucket = optional(string)
      backupRetainDays = optional(number)
      backupLocation = optional(string)
      backupLock = optional(bool)
      admins = optional(list(object({
        id = string
      })))
      objectAdmins = optional(list(object({
        id = string
      })))
      objectViewers = optional(list(object({
        id = string
      })))
      replicas = optional(number)
      path = optional(string)
      uptimePath = optional(string)
      timeout = optional(number)
      runtime = optional(string)
      memoryRequest = optional(number)
      secrets = optional(map(string))
      env = optional(map(string))
      publishers = optional(list(object({
        id = string
      })))
      subscribers = optional(list(object({
        id = string
      })))
      awsPolicy = optional(object({
        Version = string
        Statement = list(object({
          Effect = string
          Action = list(string)
          Resource = string
        }))
      }))
    })))
  })
  description = "Resources as JSON (see README.md). You can read values from a YAML file with yamldecode()."
}
