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

# CI/CD

resource "aws_iam_role_policy_attachment" "cicd_policies" {
  depends_on = [ aws_iam_role.cicd ]
  for_each   = {for item in (var.create_cicd_role ? var.cicd_policies : []): item => item}

  role       = aws_iam_role.cicd[0].name
  policy_arn = each.value
}

resource "aws_iam_user_policy_attachment" "cicd_policies" {
  depends_on = [ aws_iam_user.cicd ]
  for_each   = {for item in (var.create_cicd_service_account ? var.cicd_policies : []): item => item}

  user       = aws_iam_user.cicd[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "cicd_deploy" {
  depends_on = [ aws_iam_role.cicd ]
  count      = var.create_cicd_role ? 1 : 0

  role       = aws_iam_role.cicd[0].name
  policy_arn = aws_iam_policy.cicd_deploy[0].arn
}

resource "aws_iam_user_policy_attachment" "cicd_deploy" {
  depends_on = [ aws_iam_user.cicd ]
  count      = var.create_cicd_service_account ? 1 : 0

  user       = aws_iam_user.cicd[0].name
  policy_arn = aws_iam_policy.cicd_deploy[0].arn
}

# Gateway role

resource "aws_iam_role_policy_attachment" "gateway_policies" {
  depends_on = [ aws_iam_role.gateway ]
  for_each   = {for item in (var.create_service_accounts ? var.gateway_policies : []): item => item}

  role       = aws_iam_role.gateway[0].name
  policy_arn = each.value
}

# Topics

resource "aws_iam_user_policy_attachment" "topic_publish_permission" {
  depends_on = [ aws_iam_user.service_account ]
  for_each   = {for item in local.topicPublishers: item.key => item}

  user       = each.value.userId
  policy_arn = aws_iam_policy.topic_publisher[each.value.topicId].arn
}

resource "aws_iam_user_policy_attachment" "topic_subscribe_permission" {
  depends_on = [ aws_iam_user.service_account ]
  for_each   = {for item in local.topicSubscribers: item.key => item}

  user       = each.value.userId
  policy_arn = aws_iam_policy.topic_subscriber[each.value.topicId].arn
}

# Buckets

resource "aws_iam_user_policy_attachment" "bucket_admin_permission" {
  depends_on = [ aws_iam_user.service_account ]
  for_each   = {for item in local.bucketAdmins: item.key => item}

  user       = each.value.userId
  policy_arn = aws_iam_policy.bucket_admin[each.value.bucketId].arn
}

resource "aws_iam_user_policy_attachment" "bucket_object_admin_permission" {
  depends_on = [ aws_iam_user.service_account ]
  for_each   = {for item in local.bucketObjectAdmins: item.key => item}

  user       = each.value.userId
  policy_arn = aws_iam_policy.bucket_admin[each.value.bucketId].arn
}

resource "aws_iam_user_policy_attachment" "bucket_object_viewer_permission" {
  depends_on = [ aws_iam_user.service_account ]
  for_each   = {for item in local.bucketObjectViewers: item.key => item}

  user       = each.value.userId
  policy_arn = aws_iam_policy.bucket_admin[each.value.bucketId].arn
}

# Functions

resource "aws_iam_role_policy" "function_aws_policy" {
  for_each = {for item in local.functionsWithPolicyById: item.id => item}

  role = aws_iam_role.function[each.key].id
  policy = jsonencode(local.functionsForPermissionsById[each.key].permissionPolicy)
}

resource "aws_iam_role_policy_attachment" "function_vpcaccessor" {
  for_each = {for item in local.functionsForPermissionsById: item.id => item}

  role = aws_iam_role.function[each.key].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "secretreader" {
  for_each = {for item in local.functionsForPermissionsById: item.id => item}

  role = aws_iam_role.function[each.key].id
  policy = data.aws_iam_policy_document.secretreader[each.key].json
}

data "aws_iam_policy_document" "secretreader" {
  for_each = {for item in local.functionsForPermissionsById: item.id => item}

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      for envvar, secret in each.value.secrets:
      "${local.secret_resource_path}/${secret}-*"
    ]
  }
}

# API Gateway

resource "aws_lambda_permission" "apigw" {
  depends_on = [ aws_lambda_function.function ]
  for_each = {for item in (local.gatewayEnabled ? values(local.gatewayFunctionsById) : []): item.id => item}

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.project}-${each.key}-${var.env}"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.gateway[0].execution_arn}/*/*"
}
