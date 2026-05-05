resource "aws_s3_bucket" "avatars" {
  bucket = "grocerymate-avatars-70223957"

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "avatars_folder" {
  bucket = aws_s3_bucket.avatars.id
  key    = "avatars/"
}

resource "aws_s3_bucket_versioning" "avatars_versioning" {
  bucket = aws_s3_bucket.avatars.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "avatars_block" {
  bucket = aws_s3_bucket.avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "default_avatar" {
  bucket       = aws_s3_bucket.avatars.id
  key          = "avatars/user_default.png"
  source       = "${path.module}/../backend/avatar/user_default.png"
  content_type = "image/png"
}

resource "aws_s3_bucket_policy" "avatars_policy" {
  bucket = aws_s3_bucket.avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2RoleListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_s3_role.arn
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.avatars.arn
        ]
      },
      {
        Sid    = "AllowEC2RoleObjectAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_s3_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.avatars.arn}/avatars/*"
        ]
      }
    ]
  })
}