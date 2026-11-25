resource "aws_s3_object" "app_config" {
  bucket       = module.deploy.bucket_name
  key          = "config/app.env"
  content_type = "text/plain"
  content      = <<-EOT
    DJANGO_SETTINGS_MODULE=config.settings_production
    DJANGO_ALLOWED_HOSTS=${local.app_fqdn},${local.origin_fqdn}
    APP_FQDN=${local.app_fqdn}
    DB_HOST=${module.rds.endpoint}
    DB_PORT=5432
    DB_NAME=${module.rds.db_name}
    DB_USER=${module.rds.username}
    REDIS_HOST=${try(module.cache[0].endpoint, "")}
    AWS_STORAGE_BUCKET_NAME=${local.names.attachments_bucket}
    AWS_S3_REGION_NAME=${var.region}
    APP_SECRET_ID=${local.names.app_secret}
  EOT
}

resource "aws_s3_object" "release" {
  bucket       = module.deploy.bucket_name
  key          = "config/release.txt"
  content_type = "text/plain"
  content      = var.app_version
}