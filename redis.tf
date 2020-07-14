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

data "aws_ssm_parameter" "redis_secret" {
  count  = length(local.redisDatabasesById)
  name   = "${local.secret_name_path}/${values(local.redisDatabasesById)[count.index].secret}"
}

resource "aws_elasticache_subnet_group" "redis" {
  count                         = length(local.redisDatabasesById)

  name                          = values(local.redisDatabasesById)[count.index].name
  subnet_ids                    = var.elasticache_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  count                         = length(local.redisDatabasesById)

  automatic_failover_enabled    = try(values(local.redisDatabasesById)[count.index].replicas, 1) > 1
  availability_zones            = try(values(local.redisDatabasesById)[count.index].zones, null)
  replication_group_id          = values(local.redisDatabasesById)[count.index].name
  replication_group_description = values(local.redisDatabasesById)[count.index].name
  node_type                     = try(values(local.redisDatabasesById)[count.index].machineType, "cache.t2.small")
  number_cache_clusters         = try(values(local.redisDatabasesById)[count.index].replicas, 1)
  parameter_group_name          = "default.redis5.0"
  port                          = 6379

  subnet_group_name             = aws_elasticache_subnet_group.redis[count.index].name
  security_group_ids            = var.elasticache_security_group_ids

  transit_encryption_enabled    = true
  auth_token                    = data.aws_ssm_parameter.redis_secret[count.index].value

  lifecycle {
    ignore_changes = [ number_cache_clusters ]
  }
}

resource "aws_elasticache_cluster" "redis" {
  count                = length(local.redisDatabasesById)

  cluster_id           = values(local.redisDatabasesById)[count.index].name
  replication_group_id = aws_elasticache_replication_group.redis[count.index].id
}
