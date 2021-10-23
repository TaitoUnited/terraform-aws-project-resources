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

resource "aws_route53_zone" "zone" {
  for_each = {for item in (var.create_domain && local.ingress.enabled && local.ingress.createMainDomain ? local.mainDomains : []): item => item}

  name            = each.value

  tags = {
    Environment   = var.env
  }
}

data "aws_route53_zone" "zone" {
  depends_on      = [ aws_route53_zone.zone ]
  for_each        = {for item in local.mainDomains: item => item}

  name            = each.value
}

resource "aws_acm_certificate" "domain_cert" {
  for_each = {for item in (var.create_domain_certificate && local.ingress.enabled ? local.domains: []): item.name => item}

  domain_name       = each.value.name
  validation_method = "DNS"
}

resource "aws_route53_record" "domain_cert_validation_record" {
  for_each = {for item in (var.create_domain_certificate && local.ingress.enabled ? local.domains: []): item.name => item}

  name    = aws_acm_certificate.domain_cert[each.value.name].domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.domain_cert[each.value.name].domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone[each.value.name].id
  records = [aws_acm_certificate.domain_cert[each.value.name].domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "domain_cert_validation" {
  for_each = {for item in (var.create_domain_certificate && local.ingress.enabled ? local.domains: []): item.name => item}

  certificate_arn         = aws_acm_certificate.domain_cert[each.value.name].arn
  validation_record_fqdns = [ aws_route53_record.domain_cert_validation_record[each.value.name].fqdn ]
}
