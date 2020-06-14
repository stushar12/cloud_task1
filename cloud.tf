provider "aws"{
region    = "ap-south-1"
profile   = "tushar"
}




resource "aws_s3_bucket" "bucket1805718" {

        bucket = "bucket1805718"
	acl = "public-read-write"
	tags = {
		Name = "bucket1805718"
	}
}
 



resource "aws_s3_bucket_object" "image-jpg" {
depends_on = [
aws_s3_bucket.bucket1805718,
]
bucket = "bucket1805718"
	key = "image.jpg"
   source = "C:/Users/KIIT/Desktop/teraform/task_1/image.jpg"
	
	acl = "public-read-write"
}

locals {
	s3_origin_id = "s3-origin"
}





resource "aws_cloudfront_distribution" "my-s3-distribution" {
depends_on = [
aws_s3_bucket_object.image-jpg,
]
	enabled = true
	is_ipv6_enabled = true
	
	origin {
		domain_name = aws_s3_bucket.bucket1805718.bucket_regional_domain_name
		origin_id = local.s3_origin_id
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	default_cache_behavior {
		target_origin_id = local.s3_origin_id
		allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    	cached_methods  = ["HEAD", "GET", "OPTIONS"]

    	forwarded_values {
      		query_string = false
      		cookies {
        		forward = "none"
      		}
		}

		viewer_protocol_policy = "redirect-to-https"
    	min_ttl                = 0
    	default_ttl            = 120
    	max_ttl                = 86400
	}

	viewer_certificate {
    	cloudfront_default_certificate = true
  	}
}



output "myoutput1"{
value     = aws_cloudfront_distribution.my-s3-distribution.domain_name
}