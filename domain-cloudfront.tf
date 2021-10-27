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

resource "aws_route53_record" "cloudfront_domain_record" {
  for_each        = {for item in (local.cloudfrontEnabled ? local.domains : []): item.name => item}

  type    = "A"
  name    = each.value.name
  zone_id = data.aws_route53_zone.zone[each.key].id

  alias {
    evaluate_target_health = true
    name    = aws_cloudfront_distribution.distribution[each.key].domain_name
    zone_id = aws_cloudfront_distribution.distribution[each.key].hosted_zone_id
  }
}
