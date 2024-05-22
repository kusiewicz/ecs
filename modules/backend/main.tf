resource "aws_security_group" "ecs" {
  name        = "ecs"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "app" {
  name = "app"

  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = true
}

data "aws_ecr_lifecycle_policy_document" "app" {
  rule {
    priority    = 1
    description = "Expire images older than 3 days"

    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 3
    }
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = data.aws_ecr_lifecycle_policy_document.app.json
}

data "aws_iam_policy_document" "ecs_secrets_manager_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.var2.arn,
    ]
  }
}

resource "aws_iam_policy" "ecs_secrets_manager_access" {
  name        = "ecs_secrets_manager_access"
  description = "Allow ECS tasks to access secrets in Secrets Manager"
  policy      = data.aws_iam_policy_document.ecs_secrets_manager_access.json
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_manager_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_manager_access.arn
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "cluster" {
  name = "app-cluster"
}

resource "aws_secretsmanager_secret" "var2" {
  name = "VAR__2"
}

resource "aws_secretsmanager_secret_version" "var2" {
  secret_id     = aws_secretsmanager_secret.var2.id
  secret_string = "production2"
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "app-task-logs"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "task" {
  family                   = "app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "app-container"
      image = "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [{
        containerPort = 8000,
        hostPort      = 8000,
        protocol      = "tcp"
      }]
      environment = [
        {
          name  = "VAR1"
          value = var.var1
        },
      ]
      secrets = [
        {
          name      = "VAR__2"
          valueFrom = aws_secretsmanager_secret_version.var2.arn
        },
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    },
  ])
}

resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "app-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
    # assign_public_ip = false
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app-container"
    container_port   = 8000
  }
}
