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

data "aws_sqs_queue" "function_sqs_source" {
  for_each = local.functionSqsSourcesById

  name  = each.value.name
}

resource "aws_lambda_event_source_mapping" "function_sqs_source" {
  for_each = local.functionSqsSourcesById

  event_source_arn = data.aws_sqs_queue.function_sqs_source[each.key].arn
  function_name    = aws_lambda_function.function[each.value.function.id].arn
  batch_size       = each.value.batchSize
}
