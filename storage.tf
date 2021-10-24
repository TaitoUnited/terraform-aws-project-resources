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

resource "aws_s3_bucket" "bucket" {
  for_each = {for item in local.bucketsById: item.name => item}

  bucket = each.value.name
  # DEPRECATED: region = each.value.location

  tags = {
    project = var.project
    env     = var.env
    purpose = "storage"
  }

  dynamic "cors_rule" {
    for_each = each.value.corsRules != null ? each.value.corsRules : []
    content {
      allowed_origins  = cors_rule.value.allowedOrigins
      allowed_methods  = coalesce(cors_rule.value.allowedMethods, ["GET","HEAD"])
      allowed_headers  = coalesce(cors_rule.value.allowedHeaders, ["*"])
      expose_headers   = coalesce(cors_rule.value.exposeHeaders, [])
      max_age_seconds  = coalesce(cors_rule.value.maxAgeSeconds, 5)
    }
  }

  versioning {
    enabled = coalesce(each.value.versioningEnabled, false)
  }

  lifecycle_rule {
    id = "storageClass"
    enabled = (
      each.value.storageClass != null
      && each.value.storageClass != "STANDARD_IA"
    )
    transition {
      days = 0
      storage_class = (
        each.value.storageClass != null
        && each.value.storageClass != "STANDARD_IA"
          ? each.value.storageClass
          : "GLACIER"
      )
    }
  }

  lifecycle_rule {
    id = "transition"
    enabled = each.value.transitionRetainDays != null
    transition {
      days = each.value.transitionRetainDays
      storage_class = (
        each.value.transitionStorageClass != null
          ? each.value.transitionStorageClass
          : "GLACIER"
      )
    }
  }

  lifecycle_rule {
    id = "versioning"
    enabled = each.value.versioningRetainDays != null
    noncurrent_version_expiration {
      days = each.value.versioningRetainDays
    }
  }

  lifecycle_rule {
    id = "autoDeletion"
    enabled = each.value.autoDeletionRetainDays != null
    expiration {
      days = each.value.autoDeletionRetainDays
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
