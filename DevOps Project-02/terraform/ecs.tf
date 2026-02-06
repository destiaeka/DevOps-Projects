data "aws_iam_role" "labrole" {
  name = "LabRole"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs_task" {
  name   = "ecs-task-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "djanggo-cluster-fargate" {
  name = "djanggo-cluster-fargate"
}

    resource "aws_ecs_task_definition" "taskdefinition-django-fargate" {
    family                   = "django-task"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = "256"
    memory                   = "512"

    execution_role_arn = data.aws_iam_role.labrole.arn
    task_role_arn = data.aws_iam_role.labrole.arn

    container_definitions = jsonencode([
        {
        name      = "django"
        image     = "${aws_ecr_repository.djanggo.repository_url}:latest"
        essential = true

        portMappings = [
            {
            containerPort = 8000
            protocol      = "tcp"
            }
        ]
        }
    ])
    }

resource "aws_ecs_service" "django_service" {
  name            = "django-service"
  cluster         = aws_ecs_cluster.djanggo-cluster-fargate.id
  task_definition = aws_ecs_task_definition.taskdefinition-django-fargate.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
}
