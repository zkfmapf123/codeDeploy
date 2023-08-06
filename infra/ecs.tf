#############################################################
# ALB (ECS + Backend)
#############################################################
module "alb-todolist" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "todolist-alb-poc"

  vpc_id = aws_vpc.vpc.id
  subnets = values({
    for i, v in aws_subnet.publics :
    i => v.id
  })
  security_groups = [aws_security_group.todolist-alb-sg.id]

  target_groups = [
    {
      name             = "blue-todolist-tg"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    },
    {
      name             = "grenn-todolist-tg"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

output "v" {
  value = module.alb-todolist
}

#############################################################
# ECR
#############################################################
resource "aws_ecr_repository" "todolist" {
  name                 = "todolist-repository-poc" // repository_url
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.todolist.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

#############################################################
# ECS Cluster
#############################################################
resource "aws_kms_key" "kms" {
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "todolist-log-group" {
  name = "todolist-logs-poc"
}

resource "aws_ecs_cluster" "cluster" {
  name = "todolist-cluster-poc"

  ## Cluster Metric
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.todolist-log-group.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-provider" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 3
  }
}

#############################################################
# ECS Task Definition
#############################################################

#########################################################################
#### container_definitions.name 과 aws_ecs_service의 load_balancer에 container name이 같아야합니다.
#########################################################################
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "todolist-family"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs.arn
  task_role_arn      = aws_iam_role.ecs.arn
  network_mode       = "awsvpc"

  container_definitions = jsonencode([
    {
      name      = "healthcheck-container-poc"
      image     = "zkfmapf123/healthcheck"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        "containerPort" : 3000,
        "hostPort" : 3000,
        "protocol" : "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/todolist-ecs-family-poc" # CloudWatch 로그 그룹 이름
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "ap-northeast-2" # AWS 리전 이름
          "awslogs-stream-prefix" = "ecs"            # 로그 스트림의 접두사
        }
      },
      environment = [
        {
          "name" : "PORT",
          "value" : "3000"
        }
      ]
    }
  ])
}

## 기존 서비스는 삭제되고 만들어짐 (CodeDeploy용으로...)
resource "aws_ecs_service" "service" {
  launch_type     = "FARGATE"
  name            = "healthcheck-container-poc"
  cluster         = aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    subnets = values({
      for i, v in aws_subnet.publics :
      i => v.id
    })
    security_groups = [aws_security_group.todolist-ecs-sg.id]
  }

  force_new_deployment = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = module.alb-todolist.target_group_arns[0]
    container_name   = "healthcheck-container-poc"
    container_port   = 3000
  }

  ## 서비스를 중단하지 않고, 새로운 서비스가 활성화된 경우에만 폐기된다.
  lifecycle {
    create_before_destroy = true
  }
}
