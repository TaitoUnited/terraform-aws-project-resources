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

resource "aws_iam_role" "role" {
  for_each = local.rolesById

  name = each.value.name
  assume_role_policy = jsonencode(
    try(each.value.assumeRolePolicy, local.default_assume_role_policy)
  )
}

resource "aws_iam_role_policy" "role_aws_policy" {
  for_each = {for item in local.rolesWithPolicyById: item.name => item}

  role = aws_iam_role.role[each.key].id
  policy = jsonencode(local.rolesWithPolicyById[each.key].awsPolicy)
}


resource "aws_iam_role" "gateway" {
  count = var.create_service_accounts ? 1 : 0
  name = "${var.project}-${var.env}-gateway"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

data "aws_iam_role" "gateway" {
  depends_on = [ aws_iam_role.gateway ]
  name = "${var.project}-${var.env}-gateway"
}

resource "aws_iam_role" "cicd" {
  count = var.create_cicd_role ? 1 : 0
  name = "${var.project}-${var.env}-cicd"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
