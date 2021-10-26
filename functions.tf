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

/* Function */

# TODO: use layers https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html
resource "aws_lambda_function" "function" {
  for_each = {for item in local.functionsById: item.id => item}

  function_name  = "${var.project}-${each.key}-${var.env}"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = var.functions_bucket
  s3_key    = "${var.functions_path}/${var.build_image_tag}/${each.key}.zip"

  handler = "index.handler"

  timeout = (
    each.value.timeout != ""
      ? each.value.timeout
      : 3
  )

  runtime = (
    each.value.runtime != ""
      ? each.value.runtime
      : "nodejs12.x"
  )

  memory_size = (
    each.value.memoryRequest != ""
      ? split("M", each.value.memoryRequest)[0]
      : 128
  )

  vpc_config {
    subnet_ids = var.function_subnet_ids
    security_group_ids = var.function_security_group_ids
  }

  role = aws_iam_role.function[each.key].arn

  environment {
    variables = merge(
      each.value.env,
      {
        for key, value in each.value.secrets:
        "${key}_PARAM" => value
      }
    )
  }
}

/* Role */

resource "aws_iam_role" "function" {
  for_each = {for item in local.functionsById: item.id => item}

  name  = "${var.project}-${each.key}-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

/* Routing */

resource "aws_api_gateway_resource" "function_parent_path" {
  for_each = {for item in local.gatewayFunctionsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  parent_id   = aws_api_gateway_rest_api.gateway[0].root_resource_id
  path_part   = replace(each.value.path, "/", "")
}

resource "aws_api_gateway_resource" "function_path" {
  for_each = {for item in local.gatewayFunctionsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  parent_id   = aws_api_gateway_resource.function_parent_path[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "function_path" {
  for_each = {for item in local.gatewayFunctionsById: item.id => item}

  rest_api_id   = aws_api_gateway_rest_api.gateway[0].id
  resource_id   = aws_api_gateway_resource.function_path[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "function" {
  for_each = {for item in local.gatewayFunctionsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_method.function_path[each.key].resource_id
  http_method = aws_api_gateway_method.function_path[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function[each.key].invoke_arn
}
