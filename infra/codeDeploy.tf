#############################################
### ECS Code Deploy
#############################################
resource "aws_codedeploy_app" "ecs_code_deploy" {
  compute_platform = "ECS"
  name             = "poc-cd-app"
}

resource "aws_codedeploy_deployment_group" "ecs_code_deploy_group" {
  app_name               = aws_codedeploy_app.ecs_code_deploy.name
  deployment_group_name  = "bluegreen-deploy"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = module.alb-todolist.http_tcp_listener_arns
      }

      ## Blue
      target_group {
        name = module.alb-todolist.target_group_names[0]
      }

      ## Green
      target_group {
        name = module.alb-todolist.target_group_names[1]
      }
    }
  }
}


