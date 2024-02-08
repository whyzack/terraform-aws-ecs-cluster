resource "aws_ssm_parameter" "cluster_arn" {
  name  = "/${var.environment}/${var.name}/cluster_arn"
  type  = "String"
  value = aws_ecs_cluster.this.arn
}

resource "aws_ssm_parameter" "cluster_name" {
  name  = "/${var.environment}/${var.name}/cluster_name"
  type  = "String"
  value = aws_ecs_cluster.this.name
}