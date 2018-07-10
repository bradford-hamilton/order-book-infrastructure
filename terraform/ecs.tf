resource "aws_ecs_cluster" "main" {
  name = "ob-cluster"
}

data "template_file" "ob_app" {
  template = "${file("terraform/templates/ecs/ob_app.json.tpl")}"

  vars {
    app_image      = "${var.app_image}"
    fargate_cpu    = "${var.fargate_cpu}"
    fargate_memory = "${var.fargate_memory}"
    aws_region     = "${var.aws_region}"
    app_port       = "${var.app_port}"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "ob-app-task"
  execution_role_arn       = "${var.ecs_task_execution_role}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  container_definitions    = "${data.template_file.ob_app.rendered}"
}

resource "aws_ecs_service" "main" {
  name            = "ob-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.app_count}"
  launch_type     = "FARGATE"

  # health_check_grace_period_seconds = 7200

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_tasks.id}"]
    subnets          = ["${aws_subnet.private.*.id}"]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.id}"
    container_name   = "ob-app"
    container_port   = "${var.app_port}"
  }
  depends_on = [
    "aws_alb_listener.front_end",
  ]
}