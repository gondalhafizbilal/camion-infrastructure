resource "aws_iam_role" "flowlogs" {
  name = "flowlogs-${var.settings["main"]["name"]}"
  path = "/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "flowlog_delivery" {
  name        = "flowlog-cloudwatch-delivery"
  description = "Allows VPC Flow Logs to publish to CloudWatch Logs"
  
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:log-group:/aws/flowlogs/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "flowlog_delivery_attachment" {
  role       = aws_iam_role.flowlogs.name
  policy_arn = aws_iam_policy.flowlog_delivery.arn
}
