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

resource "aws_ecr_repository" "image" {
  for_each = {for item in local.containerRegistryTargets: item => item}

  name  = "${var.container_image_repository_path}/${each.value}"
}

resource "aws_ecr_repository" "builder" {
  for_each = {for item in local.containerRegistryTargets: item => item}

  name  = "${var.container_image_repository_path}/${each.value}-builder"
}
