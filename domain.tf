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

resource "aws_route53_zone" "zone" {
  count           = var.create_domain && local.ingress.enabled && local.ingress.createMainDomain ? length(local.mainDomains) : 0
  name            = local.mainDomains[count.index]

  tags = {
    Environment   = var.env
  }
}

data "aws_route53_zone" "zone" {
  depends_on      = [ aws_route53_zone.zone ]
  count           = length(local.mainDomains)
  name            = local.mainDomains[count.index]
}

resource "aws_acm_certificate" "domain_cert" {
  count             = var.create_domain_certificate && local.ingress.enabled ? length(local.domains) : 0
  domain_name       = local.domains[count.index].name
  validation_method = "DNS"
}

resource "aws_route53_record" "domain_cert_validation_record" {
  count   = var.create_domain_certificate && local.ingress.enabled ? length(local.domains) : 0
  name    = aws_acm_certificate.domain_cert[count.index].domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.domain_cert[count.index].domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone[count.index].id
  records = [aws_acm_certificate.domain_cert[count.index].domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "domain_cert_validation" {
  count                   = var.create_domain_certificate && local.ingress.enabled ? length(local.domains) : 0
  certificate_arn         = aws_acm_certificate.domain_cert[count.index].arn
  validation_record_fqdns = [ aws_route53_record.domain_cert_validation_record[count.index].fqdn ]
}
