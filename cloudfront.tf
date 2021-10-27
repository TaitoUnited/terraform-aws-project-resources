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

data "aws_s3_bucket" "static_assets" {
  bucket = var.static_assets_bucket
}

locals {
  s3_origin_id = "${var.project}-${var.env}-s3"
  gateway_origin_id = "${var.project}-${var.env}-gateway"
}

resource "aws_cloudfront_origin_access_identity" "OAI" {
  comment = "${var.project}-${var.env}-s3"
}

resource "aws_cloudfront_distribution" "distribution" {
  for_each = {for item in (local.cloudfrontEnabled ? local.domains : []): item.name => item}

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = concat(
    [ each.value.name ],
    [ for alt in each.value.altDomains: alt.name ]
  )

  # TODO: add restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  /* TODO: add logging
  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }
  */

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # S3
  origin {
    domain_name = data.aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    origin_path = var.static_assets_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.OAI.cloudfront_access_identity_path
    }
  }

  # API Gateway
  dynamic "origin" {
    for_each = length(aws_api_gateway_deployment.gateway) > 0 ? [ 1 ] : []
    content {
      domain_name = replace(aws_api_gateway_deployment.gateway[0].invoke_url, "/^https?://([^/]*).*/", "$1")
      origin_id   = local.gateway_origin_id

      custom_origin_config {
    		http_port              = 80
    		https_port             = 443
    		origin_protocol_policy = "https-only"
    		origin_ssl_protocols   = ["TLSv1.2"]
    	}
    }
  }

  # S3 as default origin
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # API Gateway (functions)
  dynamic "ordered_cache_behavior" {
    for_each = local.cloudfrontFunctionsById
    content {
      path_pattern     = "${ordered_cache_behavior.value.path}/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
      cached_methods   = []
      target_origin_id = local.gateway_origin_id

      forwarded_values {
        query_string = true
        cookies {
          forward      = "all"
        }
      }

      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  # S3 (static assets)
  dynamic "ordered_cache_behavior" {
    for_each = local.cloudfrontStaticContentsById
    content {
      path_pattern     = "${ordered_cache_behavior.value.path}/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = local.s3_origin_id

      forwarded_values {
        query_string = false
        headers      = ["Origin"]

        cookies {
          forward = "none"
        }
      }

      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

}