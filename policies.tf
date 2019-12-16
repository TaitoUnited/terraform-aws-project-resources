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

resource "aws_iam_policy" "bucketuser" {
  count  = var.functions_bucket != "" ? 1 : 0
  name   = "${var.project}-${var.env}-bucketuser"
  policy = data.aws_iam_policy_document.bucketuser[count.index].json
}

data "aws_iam_policy_document" "bucketuser" {
  count  = var.functions_bucket != "" ? 1 : 0
  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${var.functions_bucket}",
    ]
  }
}
