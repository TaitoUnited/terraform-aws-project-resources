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

/* Root path routing: / */

resource "aws_api_gateway_method" "static_root_path" {
  # TODO: count = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0
  count         = local.gatewayEnabled ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.gateway[0].id
  resource_id   = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "static_root_path" {
  for_each = {for item in local.gatewayRootStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_method.static_root_path[0].resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method

  integration_http_method = "GET"
  type                    = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri                     = "arn:aws:apigateway:${var.region}:s3:path/${var.static_assets_bucket}/${var.static_assets_path}/${var.build_image_tag}/${each.value.id}/index.html"
  credentials             = data.aws_iam_role.gateway.arn
}

/* Parent path routing: /PATH/ */

resource "aws_api_gateway_resource" "static_parent_path" {
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  parent_id   = aws_api_gateway_rest_api.gateway[0].root_resource_id
  path_part   = replace(each.value.path, "/", "")
}

resource "aws_api_gateway_method" "static_parent_path" {
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id   = aws_api_gateway_rest_api.gateway[0].id
  resource_id   = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "static_parent_path" {
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_method.static_parent_path[each.key].resource_id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method

  integration_http_method = "GET"
  type                    = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri                     = "arn:aws:apigateway:${var.region}:s3:path/${var.static_assets_bucket}/${var.static_assets_path}/${var.build_image_tag}/${each.value.id}/index.html"
  credentials             = data.aws_iam_role.gateway.arn
}

/* Path routing: /PATH/{proxy+} */

resource "aws_api_gateway_resource" "static_path" {
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  parent_id   = (
    replace(each.value.path, "/", "") != ""
      ? aws_api_gateway_resource.static_parent_path[each.key].id
      : aws_api_gateway_rest_api.gateway[0].root_resource_id
  )
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "static_path" {
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id   = aws_api_gateway_rest_api.gateway[0].id
  resource_id   = aws_api_gateway_resource.static_path[each.key].id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "static_path" {
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_method.static_path[each.key].resource_id
  http_method = aws_api_gateway_method.static_path[each.key].http_method

  integration_http_method = "GET"
  type                    = "AWS"

  cache_key_parameters = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri                     = "arn:aws:apigateway:${var.region}:s3:path/${var.static_assets_bucket}/${var.static_assets_path}/${var.build_image_tag}/${each.value.id}/index.html"
  credentials             = data.aws_iam_role.gateway.arn
}

/* Responses: / */

resource "aws_api_gateway_method_response" "static_root_static_path_status_200" {
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "static_root_static_path_status_400" {
  depends_on  = [ aws_api_gateway_integration.static_root_path ]
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "static_root_static_path_status_500" {
  depends_on  = [ aws_api_gateway_integration.static_root_path ]
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "static_root_static_path_integration_200" {
  depends_on  = [ aws_api_gateway_integration.static_root_path ]
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = aws_api_gateway_method_response.static_root_static_path_status_200[0].status_code

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "static_root_static_path_integration_400" {
  depends_on  = [ aws_api_gateway_integration.static_root_path ]
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = aws_api_gateway_method_response.static_root_static_path_status_400[0].status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "static_root_static_path_integration_500" {
  depends_on  = [ aws_api_gateway_integration.static_root_path ]
  count       = local.gatewayEnabled && local.ingress.class == "gateway" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_rest_api.gateway[0].root_resource_id
  http_method = aws_api_gateway_method.static_root_path[0].http_method
  status_code = aws_api_gateway_method_response.static_root_static_path_status_500[0].status_code

  selection_pattern = "5\\d{2}"
}

/* Responses: /PATH/ */

resource "aws_api_gateway_method_response" "static_parent_path_status_200" {
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "static_parent_path_status_400" {
  depends_on = [ aws_api_gateway_integration.static_parent_path ]
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "static_parent_path_status_500" {
  depends_on = [ aws_api_gateway_integration.static_parent_path ]
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "static_parent_path_integration_200" {
  depends_on = [ aws_api_gateway_integration.static_parent_path ]
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_200[each.key].status_code

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "static_parent_path_integration_400" {
  depends_on = [ aws_api_gateway_integration.static_parent_path ]
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_400[each.key].status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "static_parent_path_integration_500" {
  depends_on = [ aws_api_gateway_integration.static_parent_path ]
  for_each = {for item in local.gatewayChildStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_parent_path[each.key].id
  http_method = aws_api_gateway_method.static_parent_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_500[each.key].status_code

  selection_pattern = "5\\d{2}"
}

/* Responses: /PATH/{proxy+} */

resource "aws_api_gateway_method_response" "static_path_status_200" {
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "static_path_status_400" {
  depends_on = [ aws_api_gateway_integration.static_path ]
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "static_path_status_500" {
  depends_on = [ aws_api_gateway_integration.static_path ]
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "static_path_integration_200" {
  depends_on = [ aws_api_gateway_integration.static_path ]
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_200[each.key].status_code

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "static_path_integration_400" {
  depends_on = [ aws_api_gateway_integration.static_path ]
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_400[each.key].status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "static_path_integration_500" {
  depends_on = [ aws_api_gateway_integration.static_path ]
  for_each = {for item in local.gatewayStaticContentsById: item.id => item}

  rest_api_id = aws_api_gateway_rest_api.gateway[0].id
  resource_id = aws_api_gateway_resource.static_path[each.key].id
  http_method = aws_api_gateway_method.static_path[each.key].http_method
  status_code = aws_api_gateway_method_response.static_path_status_500[each.key].status_code

  selection_pattern = "5\\d{2}"
}
