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

data "aws_ssm_parameter" "redis_secret" {
  for_each = {for item in local.redisDatabasesById: item.id => item}

  name   = "${local.secret_name_path}/${each.value.secret}"
}

resource "aws_elasticache_subnet_group" "redis" {
  for_each = {for item in local.redisDatabasesById: item.id => item}

  name                          = each.value.name
  subnet_ids                    = var.elasticache_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  for_each                      = {for item in local.redisDatabasesById: item.id => item}

  automatic_failover_enabled    = coalesce(each.value.replicas, 1) > 1
  preferred_cache_cluster_azs   = coalesce(each.value.zones, null)
  replication_group_id          = each.value.name
  description                   = each.value.name
  node_type                     = coalesce(each.value.machineType, "cache.t2.small")
  num_cache_clusters            = coalesce(each.value.replicas, 1)
  parameter_group_name          = "default.redis5.0"
  port                          = 6379

  subnet_group_name             = aws_elasticache_subnet_group.redis[each.key].name
  security_group_ids            = var.elasticache_security_group_ids

  transit_encryption_enabled    = true
  auth_token                    = data.aws_ssm_parameter.redis_secret[each.key].value

  lifecycle {
    ignore_changes = [ num_cache_clusters ]
  }
}

resource "aws_elasticache_cluster" "redis" {
  for_each             = {for item in local.redisDatabasesById: item.id => item}

  cluster_id           = each.value.name
  replication_group_id = aws_elasticache_replication_group.redis[each.key].id
}
