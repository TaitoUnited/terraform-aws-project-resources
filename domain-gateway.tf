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

data "aws_acm_certificate" "domain_cert" {
  for_each        = {for item in (local.gatewayEnabled ? local.domains : []): item.name => item}

  domain          = each.value.name
}

resource "aws_api_gateway_domain_name" "domain" {
  for_each        = {for item in (local.gatewayEnabled ? local.domains : []): item.name => item}

  domain_name     = each.value.name
  certificate_arn = data.aws_acm_certificate.domain_cert[each.value.name].arn
}

resource "aws_api_gateway_base_path_mapping" "base_path" {
  for_each        = {for item in (local.gatewayEnabled ? local.domains : []): item.name => item}

  domain_name     = aws_api_gateway_domain_name.domain[each.value.name].domain_name
  api_id          = aws_api_gateway_rest_api.gateway[0].id
  stage_name      = aws_api_gateway_stage.gateway[0].stage_name
}

resource "aws_route53_record" "domain_record" {
  for_each        = {for item in (local.gatewayEnabled ? local.domains : []): item.name => item}

  type            = "A"
  name            = aws_api_gateway_domain_name.domain[each.value.name].domain_name
  zone_id         = data.aws_route53_zone.zone[each.value.name].id

  alias {
    evaluate_target_health = true
    name          = aws_api_gateway_domain_name.domain[each.value.name].cloudfront_domain_name
    zone_id       = aws_api_gateway_domain_name.domain[each.value.name].cloudfront_zone_id
  }
}
