resource "aws_cloudwatch_log_group" "ob_log_group" {
  name              = "/ecs/ob-app"
  retention_in_days = 30

  tags {
    Name = "ob-log-group"
  }
}

resource "aws_cloudwatch_log_stream" "ob_log_stream" {
  name           = "ob-log-stream"
  log_group_name = "${aws_cloudwatch_log_group.ob_log_group.name}"
}
