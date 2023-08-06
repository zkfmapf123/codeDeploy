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
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.ecs.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_attachment" {
  policy_arn = aws_iam_policy.codedeploy_policy.arn
  role       = aws_iam_role.codedeploy.name
}
