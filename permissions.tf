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

# CI/CD

resource "aws_iam_role_policy_attachment" "cicd_policies" {
  depends_on = [ aws_iam_role.cicd ]
  count      = length(var.cicd_policies)
  role       = aws_iam_role.cicd.name
  policy_arn = var.cicd_policies[count.index]
}

# Gateway role

resource "aws_iam_role_policy_attachment" "gateway_policies" {
  depends_on = [ aws_iam_role.cicd ]
  count      = length(var.gateway_policies)
  role       = aws_iam_role.gateway.name
  policy_arn = var.gateway_policies[count.index]
}

# Topics

resource "aws_iam_user_policy_attachment" "topic_publish_permission" {
  depends_on = [ aws_iam_user.service_account ]
  count      = length(local.topicPublishers)
  user       = local.topicPublishers[count.index].userId
  policy_arn = aws_iam_policy.topic_publisher[
    index(keys(local.topicsById), local.topicPublishers[count.index].topicId)
  ].arn
}

resource "aws_iam_user_policy_attachment" "topic_subscribe_permission" {
  depends_on = [ aws_iam_user.service_account ]
  count      = length(local.topicSubscribers)
  user       = local.topicSubscribers[count.index].userId
  policy_arn = aws_iam_policy.topic_subscriber[
    index(keys(local.topicsById), local.topicSubscribers[count.index].topicId)
  ].arn
}

# Buckets

resource "aws_iam_user_policy_attachment" "bucket_admin_permission" {
  depends_on = [ aws_iam_user.service_account ]
  count      = length(local.bucketAdmins)
  user       = local.bucketAdmins[count.index].userId
  policy_arn = aws_iam_policy.bucket_admin[
    index(keys(local.bucketsById), local.bucketAdmins[count.index].bucketId)
  ].arn
}

resource "aws_iam_user_policy_attachment" "bucket_object_admin_permission" {
  depends_on = [ aws_iam_user.service_account ]
  count      = length(local.bucketObjectAdmins)
  user       = local.bucketObjectAdmins[count.index].userId
  policy_arn = aws_iam_policy.bucket_admin[
    index(keys(local.bucketsById), local.bucketObjectAdmins[count.index].bucketId)
  ].arn
}

resource "aws_iam_user_policy_attachment" "bucket_object_viewer_permission" {
  depends_on = [ aws_iam_user.service_account ]
  count      = length(local.bucketObjectViewers)
  user       = local.bucketObjectViewers[count.index].userId
  policy_arn = aws_iam_policy.bucket_admin[
    index(keys(local.bucketsById), local.bucketObjectViewers[count.index].bucketId)
  ].arn
}

# Functions

resource "aws_iam_role_policy" "function_aws_policy" {
  count = length(local.functionsWithPolicyById)
  role = aws_iam_role.function[count.index].name
  policy = jsonencode(values(local.functionsForPermissionsById)[count.index].awsPolicy)
}

resource "aws_iam_role_policy_attachment" "function_vpcaccessor" {
  count = length(local.functionsForPermissionsById)
  role = aws_iam_role.function[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "secretreader" {
  count = length(local.functionsForPermissionsById)
  role = aws_iam_role.function[count.index].name
  policy = data.aws_iam_policy_document.secretreader[count.index].json
}

data "aws_iam_policy_document" "secretreader" {
  count = length(local.functionsForPermissionsById)
  statement {
    actions = [
      "ssm:GetParameter",
      /* "ssm:GetParameters", */
      /* "ssm:GetParametersByPath", */
    ]

    resources = [
      for envvar, secret in values(local.functionsForPermissionsById)[count.index].secrets:
      "${local.secret_resource_path}/${secret}"
    ]
  }
}

# API Gateway

resource "aws_lambda_permission" "apigw" {
  count = local.gatewayEnabled ? length(local.gatewayFunctionsById) : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.gateway[0].execution_arn}/*/*"
}
