resource "aws_lambda_function" "lambda" {
  function_name = var.name
  role          = aws_iam_role.role.arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = var.architectures

  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)


  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table
    }
  }
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}
