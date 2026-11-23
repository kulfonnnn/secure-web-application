resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-cache"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project}-cache"
  description          = "Valkey - liczniki rate limitingu"

  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = "cache.t4g.micro"
  port                 = 6379
  parameter_group_name = "default.valkey8"

  num_cache_clusters          = 1
  preferred_cache_cluster_azs = [var.availability_zone]
  automatic_failover_enabled  = false
  multi_az_enabled            = false

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  snapshot_retention_limit = 0
  apply_immediately        = true
}