resource "random_password" "django_secret_key" {
  length  = 64
  special = false
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name                    = var.secret_name
  description             = "Dane poufne aplikacji: Django, RDS, ElastiCache"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    DJANGO_SECRET_KEY = random_password.django_secret_key.result
    DB_PASSWORD       = random_password.db.result
    REDIS_PASSWORD    = random_password.redis.result
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.endpoint_subnet_id]
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-secretsmanager-endpoint" }
}