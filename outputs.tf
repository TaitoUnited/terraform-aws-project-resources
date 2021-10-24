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

output "gateway_id" {
  value = aws_api_gateway_rest_api.gateway[*].id
}

output "stage_name" {
  value = aws_api_gateway_stage.gateway[*].stage_name
}

output "base_url" {
  value = aws_api_gateway_deployment.gateway[*].invoke_url
}

output "domain" {
  value = values(aws_api_gateway_domain_name.domain)[*].domain_name
}

output "cloudfront_domain_name" {
  value = values(aws_api_gateway_domain_name.domain)[*].cloudfront_domain_name
}

output "cloudfront_zone_id" {
  value = values(aws_api_gateway_domain_name.domain)[*].cloudfront_zone_id
}

output "redis_endpoint" {
  value = values(aws_elasticache_replication_group.redis)[*].primary_endpoint_address
}
