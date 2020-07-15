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

resource "aws_s3_bucket" "bucket" {
  count  = length(local.bucketsById)
  bucket = values(local.bucketsById)[count.index].name
  region = values(local.bucketsById)[count.index].location

  tags = {
    project = var.project
    env     = var.env
    purpose = "storage"
  }

  cors_rule {
    allowed_origins = [
      for cors in values(local.bucketsById)[count.index].cors:
      cors.domain
    ]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }

  versioning {
    enabled = values(local.bucketsById)[count.index].versioning
    mfa_delete = false # values(local.bucketsById)[count.index].versioning
  }

  lifecycle_rule {
    id = "storageClass"
    enabled = (
      try(values(local.bucketsById)[count.index].storageClass, null) != null
      && try(values(local.bucketsById)[count.index].storageClass, null) != "STANDARD_IA"
    )
    transition {
      days = 0
      storage_class = (
        try(values(local.bucketsById)[count.index].storageClass, null) != null
        && try(values(local.bucketsById)[count.index].storageClass, null) != "STANDARD_IA"
          ? try(values(local.bucketsById)[count.index].storageClass, null)
          : "GLACIER"
      )
    }
  }

  lifecycle_rule {
    id = "transition"
    enabled = try(values(local.bucketsById)[count.index].transitionRetainDays, null) != null
    transition {
      days = try(values(local.bucketsById)[count.index].transitionRetainDays, null)
      storage_class = (
        try(values(local.bucketsById)[count.index].transitionStorageClass, null) != null
          ? try(values(local.bucketsById)[count.index].transitionStorageClass, null)
          : "GLACIER"
      )
    }
  }

  lifecycle_rule {
    id = "versioning"
    enabled = try(values(local.bucketsById)[count.index].versioningRetainDays, null) != null
    noncurrent_version_expiration {
      days = try(values(local.bucketsById)[count.index].versioningRetainDays, null)
    }
  }

  lifecycle_rule {
    id = "autoDeletion"
    enabled = try(values(local.bucketsById)[count.index].autoDeletionRetainDays, null) != null
    expiration {
      days = try(values(local.bucketsById)[count.index].autoDeletionRetainDays, null)
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
