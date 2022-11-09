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

resource "aws_cloudwatch_event_rule" "function_cron_job" {
  for_each = local.functionCronJobsById

  name                = "${var.project}-${each.value.function.id}-${var.env}-${each.value.name}"
  schedule_expression = each.value.schedule
}

resource "aws_cloudwatch_event_target" "function_cron_job" {
  for_each = local.functionCronJobsById

  arn  = aws_lambda_function.function[each.value.function.id].arn
  rule = aws_cloudwatch_event_rule.function_cron_job[each.key].name
  input = jsonencode({
    type = "cronJob"
    name = each.value.name
    ruleName = aws_cloudwatch_event_rule.function_cron_job[each.key].name
    schedule = each.value.schedule
    command = each.value.command
  })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each      = local.functionCronJobsById

  statement_id  = "${var.project}-${each.value.function.id}-${var.env}-${each.value.name}-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.value.function.id].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.function_cron_job[each.key].arn
  # qualifier     = aws_lambda_alias.function.name
}
