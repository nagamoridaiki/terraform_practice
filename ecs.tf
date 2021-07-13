# ECS クラスター
resource "aws_ecs_cluster" "example" {
  name = "example"
}
# タスク定義
resource "aws_ecs_task_definition" "example" {
  family                   = "linkode-example"
  cpu                      = "256"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      "name" : "example",
      "image" : "${aws_ecr_repository.example.repository_url}:latest",
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "us-east-2",
          "awslogs-stream-prefix" : "tf-example",
          "awslogs-group" : "/ecs/example"
        }
      },
      "portMappings" : [
        {
          "protocol" : "tcp",
          "containerPort" : 3000
        }
      ]
    }
  ])
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
  task_role_arn      = aws_iam_role.ecs_task.arn
}

# ECS サービス
resource "aws_ecs_service" "example" {
  name                              = "example"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60
  network_configuration {
    assign_public_ip = false
    security_groups  = [module.tf-example_sg.security_group_id]
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_c.id,
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "example"
    container_port   = 3000
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}
module "tf-example_sg" {
  source      = "./security_group"
  name        = "tf-example-sg"
  vpc_id      = aws_vpc.example.id
  port        = 3000
  cidr_blocks = [aws_vpc.example.cidr_block]
}
# ECS タスク定義に付与する IAM ロール
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_task" {
  name               = "tf_example-ecs_task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_role_policy_attachment" "ecs_service" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
  role       = aws_iam_role.ecs_task.name
}