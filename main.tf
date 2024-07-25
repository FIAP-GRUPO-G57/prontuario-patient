provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.bucket_name
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_lambda_function" "flask_lambda" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  filename      = "lambda_function_payload.zip"

  source_code_hash  = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_bucket.bucket
    }
  }
}

resource "aws_api_gateway_rest_api" "flask_api" {
  name        = "FlaskLambdaAPI"
  description = "API Gateway for Flask app"
}

resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  parent_id   = aws_api_gateway_rest_api.flask_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.flask_api.id
  resource_id   = aws_api_gateway_resource.upload_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.upload_method.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = aws_lambda_function.flask_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.flask_api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "list_files_resource" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  parent_id   = aws_api_gateway_rest_api.flask_api.root_resource_id
  path_part   = "files"
}

resource "aws_api_gateway_method" "list_files_method" {
  rest_api_id   = aws_api_gateway_rest_api.flask_api.id
  resource_id   = aws_api_gateway_resource.list_files_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_files_integration" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  resource_id = aws_api_gateway_resource.list_files_resource.id
  http_method = aws_api_gateway_method.list_files_method.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = aws_lambda_function.flask_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_list_files" {
  statement_id  = "AllowAPIGatewayInvoke2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.flask_api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "download_resource" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  parent_id   = aws_api_gateway_rest_api.flask_api.root_resource_id
  path_part   = "download"
}

resource "aws_api_gateway_method" "download_method" {
  rest_api_id   = aws_api_gateway_rest_api.flask_api.id
  resource_id   = aws_api_gateway_resource.download_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "download_integration" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  resource_id = aws_api_gateway_resource.download_resource.id
  http_method = aws_api_gateway_method.download_method.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = aws_lambda_function.flask_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_download" {
  statement_id  = "AllowAPIGatewayInvoke3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.flask_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = "${aws_api_gateway_rest_api.flask_api.execution_arn}/*"
}
