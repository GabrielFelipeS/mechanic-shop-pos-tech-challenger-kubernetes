data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-cpf-login-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "cpf_login" {
  function_name     = var.function_name
  description       = "Issues a JWT for active customers authenticated by CPF."
  role              = aws_iam_role.execution.arn
  runtime           = "java21"
  handler           = "org.project.mechanic_shop.cpflogin.CpfLoginRequestHandler::handleRequest"
  s3_bucket         = var.artifact_bucket
  s3_key            = var.artifact_key
  s3_object_version = var.artifact_version
  timeout           = 10
  memory_size       = 512

  environment {
    variables = {
      INTERNAL_API_BASE_URL = var.internal_api_base_url
      INTERNAL_API_SECRET   = var.internal_api_secret
      JWT_ISSUER            = "mechanic-shop-api"
      JWT_SECRET            = var.jwt_secret
    }
  }

  depends_on = [aws_iam_role_policy_attachment.basic_execution]

  lifecycle {
    # The Lambda repository CI/CD owns code changes after initial provisioning.
    ignore_changes = [s3_bucket, s3_key, s3_object_version, source_code_hash]
  }
}
