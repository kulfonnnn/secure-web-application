output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "redis_password" {
  value     = random_password.redis.result
  sensitive = true
}