/**
 * Copyright 2019 Taito United
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

# AWS provider

variable "region" {
  type        = string
  description = "AWS region."
}

# Project

variable "project" {
  type        = string
  description = "Project name: e.g. \"my-project\""
}

variable "env" {
  type        = string
  description = "Environment: e.g. \"dev\""
}

variable "domain" {
  type        = string
  description = "Domain name: e.g. \"my-project-dev.mydomain.com\""
}

variable "vc_repository" {
  type        = string
  description = "Version control repository: e.g. \"my-project\""
}

# Containers

variable "create_container_registry" {
  type        = bool
  default     = false
  description = "True if container registry should be created."
}

variable "container_targets" {
  type        = list(string)
  default     = []
  description = "Container names: e.g. [ \"client\", \"server\" ]"
}

# Storage

variable "storages" {
  type        = list(string)
  default     = []
  description = "Name of each storage bucket."
}

variable "storage_locations" {
  type        = list(string)
  default     = []
  description = "Location of each storage bucket."
}

variable "storage_classes" {
  type        = list(string)
  default     = []
  description = "Storage class of each storage bucket."
}

variable "storage_days" {
  type         = list(string)
  default     = []
  description = "Archive days of each storage bucket."
}

/* Shared zone resources */

# For example: my-zone-functions
variable "functions_bucket" {
  type    = string
  default = ""
  description = "Name of the storage bucket used to store function packages."
}
