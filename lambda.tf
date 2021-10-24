provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

data "template_file" "function" {
  template = "${file("${path.module}/headers_function.js")}"
}

data "archive_file" "headers-function" {
  type        = "zip"
  output_path = "${path.module}/.zip/headers_function.zip"
  source {
    filename = "index.js"
    content  = "${data.template_file.function.rendered}"
  }
}

data "archive_file" "errors-function" {
  type        = "zip"
  source_dir  = "${path.module}/errors-function"
  output_path = "${path.module}/.zip/errors_function.zip"
}

data "aws_iam_policy_document" "lambda-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "headers-function" {
  name               = "${module.origin_label.id}-lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-role-policy.json}"
}

resource "aws_iam_role_policy_attachment" "headers-function-role-policy" {
  role       = "${aws_iam_role.headers-function.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "headers" {
  provider         = aws.us-east
  function_name    = "${replace(module.origin_label.id, ".", "-")}-headers"
  filename         = "${data.archive_file.headers-function.output_path}"
  source_code_hash = "${data.archive_file.headers-function.output_base64sha256}"
  role             = "${aws_iam_role.headers-function.arn}"
  runtime          = "nodejs12.x"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 3
  publish          = true
}

resource "aws_lambda_function" "errors_headers" {
  provider         = aws.us-east
  function_name    = "${replace(module.origin_label.id, ".", "-")}-errors"
  filename         = "${data.archive_file.errors-function.output_path}"
  source_code_hash = "${data.archive_file.errors-function.output_base64sha256}"
  role             = "${aws_iam_role.headers-function.arn}"
  runtime          = "nodejs12.x"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 3
  publish          = true
}