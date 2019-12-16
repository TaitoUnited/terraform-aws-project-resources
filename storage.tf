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

resource "aws_s3_bucket" "bucket" {
  count  = length(var.storages)
  bucket = var.storages[count.index]
  region = var.storage_locations[count.index]

  /* TODO
  storage_class = "${var.storage_classes[count.index]}"
  */

  tags = {
    project = var.project
    env     = var.env
    purpose = "storage"
  }

  /* TODO: enable localhost only for dev and feat environments */
  cors_rule {
    allowed_origins = ["http://localhost", "https://${var.domain}"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = var.storage_days[count.index]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# TODO: give service account access rights to bucket
