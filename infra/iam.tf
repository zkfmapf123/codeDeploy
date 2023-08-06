#############################################################
### ECS
#############################################################
resource "aws_iam_role" "ecs" {
  name = "pipeline-ecs-task-definition-poc"

  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ecs-execution"
  }
}

resource "aws_iam_policy" "cloudwatch-group" {
  name = "cloudwatch-group-poc"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "get_ecr_list" {
  name = "get-ecr-list-poc"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_group_attachment" {
  for_each = {
    for i, v in [aws_iam_policy.cloudwatch-group, aws_iam_policy.get_ecr_list] :
    i => v
  }

  policy_arn = each.value.arn
  role       = aws_iam_role.ecs.name
}

#############################################################
### CodeDeploy
#############################################################
resource "aws_iam_role" "codedeploy" {
  name = "codedeploy"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codedeploy.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codedeploy_policy" {
  name = "codedeploy-policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:DescribeServices",
          "ecs:UpdateServicePrimaryTaskSet",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "s3:GetObject",
          "codedeploy:PutLifecycleEventHookExecutionStatus",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_hooks" {
  name = "lambda_hooks"
  path = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction",
          "lambda:InvokeAsync",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction",
          "lambda:AddPermission",
          "lambda:RemovePermission"
          // Add any other Lambda-related actions you need here
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "codedeploy_attachment" {
  policy_arn = aws_iam_policy.codedeploy_policy.arn
  role       = aws_iam_role.codedeploy.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_lambda" {
  policy_arn = aws_iam_policy.lambda_hooks.arn
  role       = aws_iam_role.codedeploy.name
}

#############################################################
### Lambda
### https://docs.aws.amazon.com/ko_kr/codedeploy/latest/userguide/tutorial-ecs-with-hooks-create-hooks.html
#############################################################
resource "aws_iam_role" "lambda_cli_hook_role" {
  name        = "lambda-cli-hook-role"
  description = "Allows Lambda functions to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_codedeploy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = "lambda-cli-hook-role"
}

