provider "aws" {
  region = var.region
}


terraform {
  backend "s3" {
    bucket         = "fiap-tech-challenge-terraform-state"
    key            = "lambda/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.lambda_name}-policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
    ]
  })
}

data "archive_file" "dummy" {
  type          = "zip"
  output_path   = "dummy/lambda_function_payload.zip"

  source {
    content     = "hello"
    filename    = "dummy.txt"
  }
}

resource "aws_lambda_function" "lambda" {
  function_name   = "${var.lambda_name}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.handler"
  runtime         = "java21"
  filename        = "${data.archive_file.dummy.output_path}"
}