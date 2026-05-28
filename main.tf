provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = "my-secure-demo-bucket-123456"

  tags = {
    Name = "SecureDemoBucket"
  }
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create KMS Key
resource "aws_kms_key" "s3_kms" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

# Enable KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.demo_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging Bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-demo-log-bucket-123456"
}

# Enable Access Logging
resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.demo_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.demo_bucket.id

  rule {
    id     = "cleanup-rule"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# SNS Topic
resource "aws_sns_topic" "s3_events" {
  name = "s3-event-topic"
}

# Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.demo_bucket.id

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
