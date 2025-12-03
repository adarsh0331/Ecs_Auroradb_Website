provider "aws" {
  region = "us-east-1" # change to your preferred region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "ecs-aurora-terraform-state-bucket-jeetu"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "terraform-state-bucket"
    Environment = "global"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock-table"
    Environment = "global"
  }
}
