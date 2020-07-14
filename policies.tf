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

# Topics

resource "aws_iam_policy" "topic_publisher" {
  depends_on = [ aws_sns_topic.topic ]
  count  = length(local.topicsById)
  name   = "${values(local.topicsById)[count.index].name}-topic-publisher"
  policy = data.aws_iam_policy_document.topic_publisher[count.index].json
}

data "aws_iam_policy_document" "topic_publisher" {
  depends_on = [ aws_sns_topic.topic ]
  count  = length(local.topicsById)
  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:::${values(local.topicsById)[count.index].name}",
    ]
  }
}

resource "aws_iam_policy" "topic_subscriber" {
  depends_on = [ aws_sns_topic.topic ]
  count  = length(local.topicsById)
  name   = "${values(local.topicsById)[count.index].name}-topic-subscriber"
  policy = data.aws_iam_policy_document.topic_subscriber[count.index].json
}

data "aws_iam_policy_document" "topic_subscriber" {
  depends_on = [ aws_sns_topic.topic ]
  count  = length(local.topicsById)
  statement {
    actions = [
      "sns:Subscribe"
    ]

    resources = [
      "arn:aws:sns:::${values(local.topicsById)[count.index].name}",
    ]
  }
}

# Buckets

resource "aws_iam_policy" "bucket_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  name   = "${values(local.bucketsById)[count.index].name}-bucket-admin"
  policy = data.aws_iam_policy_document.bucket_admin[count.index].json
}

data "aws_iam_policy_document" "bucket_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${values(local.bucketsById)[count.index].name}",
      "arn:aws:s3:::${values(local.bucketsById)[count.index].name}/*"
    ]
  }
}

resource "aws_iam_policy" "bucket_object_viewer" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  name   = "${values(local.bucketsById)[count.index].name}-bucket-viewer"
  policy = data.aws_iam_policy_document.bucket_object_viewer[count.index].json
}

data "aws_iam_policy_document" "bucket_object_viewer" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${values(local.bucketsById)[count.index].name}/*"
    ]
  }
}

resource "aws_iam_policy" "bucket_object_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  name   = "${values(local.bucketsById)[count.index].name}-bucket-editor"
  policy = data.aws_iam_policy_document.bucket_object_admin[count.index].json
}

data "aws_iam_policy_document" "bucket_object_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  count  = length(local.bucketsById)
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${values(local.bucketsById)[count.index].name}/*"
    ]
  }
}
