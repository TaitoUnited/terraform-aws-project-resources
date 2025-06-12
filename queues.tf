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

resource "aws_sqs_queue" "queue" {
  for_each    = local.queuesById

  name        = each.value.name
  fifo_queue  = coalesce(each.value.queueType, "standard") == "fifo"

  visibility_timeout_seconds = each.value.visibilityTimeout
}

data "aws_sqs_queue" "dead_letter" {
  for_each = local.deadLetterQueuesByName
  name = each.key
}

resource "aws_sqs_queue_policy" "sqs_aws_policy" {
  for_each = {for item in local.queuesWithPolicyById: item.id => item}

  queue_url = aws_sqs_queue.queue[each.key].id
  policy = jsonencode(local.queuesWithPolicyById[each.key].accessPolicy)  
}
