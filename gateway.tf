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

# TODO: upgrade to apigatewayv2

resource "aws_api_gateway_rest_api" "gateway" {
  count       = local.gatewayEnabled ? 1 : 0
  name        = "${var.project}-${var.env}"
}

resource "aws_api_gateway_deployment" "gateway" {
  depends_on = [
    aws_api_gateway_integration.static_root_path,
    aws_api_gateway_integration.static_parent_path,
    aws_api_gateway_integration.static_path,
    aws_api_gateway_integration.function
  ]
  count       = local.gatewayEnabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id

  variables = {
    # Force recreate API GW on every deploy (no need to taint)
    build_image_tag = var.build_image_tag
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "gateway" {
  depends_on    = [ aws_api_gateway_deployment.gateway ]
  count         = local.gatewayEnabled ? 1 : 0
  stage_name    = "stage"
  rest_api_id   = aws_api_gateway_rest_api.gateway[0].id
  deployment_id = aws_api_gateway_deployment.gateway[0].id
}
