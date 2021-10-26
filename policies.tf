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

# Topics

resource "aws_iam_policy" "topic_publisher" {
  depends_on = [ aws_sns_topic.topic ]
  for_each = {for item in local.topicsById: item.id => item}

  name   = "${each.value.name}-topic-publisher"
  policy = data.aws_iam_policy_document.topic_publisher[each.key].json
}

data "aws_iam_policy_document" "topic_publisher" {
  depends_on = [ aws_sns_topic.topic ]
  for_each = {for item in local.topicsById: item.id => item}

  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:::${each.value.name}",
    ]
  }
}

resource "aws_iam_policy" "topic_subscriber" {
  depends_on = [ aws_sns_topic.topic ]
  for_each = {for item in local.topicsById: item.id => item}

  name   = "${each.value.name}-topic-subscriber"
  policy = data.aws_iam_policy_document.topic_subscriber[each.key].json
}

data "aws_iam_policy_document" "topic_subscriber" {
  depends_on = [ aws_sns_topic.topic ]
  for_each = {for item in local.topicsById: item.id => item}

  statement {
    actions = [
      "sns:Subscribe"
    ]

    resources = [
      "arn:aws:sns:::${each.value.name}",
    ]
  }
}

# Buckets

resource "aws_iam_policy" "bucket_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  name   = "${each.value.name}-bucket-admin"
  policy = data.aws_iam_policy_document.bucket_admin[each.key].json
}

data "aws_iam_policy_document" "bucket_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${each.value.name}",
      "arn:aws:s3:::${each.value.name}/*"
    ]
  }
}

resource "aws_iam_policy" "bucket_object_viewer" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  name   = "${each.value.name}-bucket-viewer"
  policy = data.aws_iam_policy_document.bucket_object_viewer[each.key].json
}

data "aws_iam_policy_document" "bucket_object_viewer" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${each.value.name}/*"
    ]
  }
}

resource "aws_iam_policy" "bucket_object_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  name   = "${each.value.name}-bucket-editor"
  policy = data.aws_iam_policy_document.bucket_object_admin[each.key].json
}

data "aws_iam_policy_document" "bucket_object_admin" {
  depends_on = [ aws_s3_bucket.bucket ]
  for_each = {for item in local.bucketsById: item.id => item}

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${each.value.name}/*"
    ]
  }
}
