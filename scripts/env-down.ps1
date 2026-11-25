# Wylacza srodowisko: zatrzymuje EC2 i RDS, usuwa ALB, ElastiCache, WAF i endpoint Secrets Managera.
$ErrorActionPreference = "Stop"
$infra = (Resolve-Path (Join-Path $PSScriptRoot "..\iac-infrastructure")).Path

$ids = aws ec2 describe-instances --filters "Name=tag:Project,Values=bsiaw" "Name=instance-state-name,Values=running,pending" --query "Reservations[].Instances[].InstanceId" --output text
if ($ids) { aws ec2 stop-instances --instance-ids $ids.Split() | Out-Null; Write-Host "EC2: zatrzymywanie $ids" }

aws rds stop-db-instance --db-instance-identifier bsiaw-db | Out-Null
Write-Host "RDS: zatrzymywanie (po 7 dniach AWS uruchomi baze automatycznie)"

# Odlaczenie WAF od CloudFront i usuniecie ACL trwa kilka minut
Push-Location $infra
try {
    terraform apply -auto-approve `
      -var="enable_alb=false" `
      -var="enable_cache=false" `
      -var="enable_waf=false" `
      -var="enable_secrets_endpoint=false"

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply nie powiodl sie."
    }
}
finally {
    Pop-Location
}

Write-Host "Kontrola: oczekiwane puste wyniki (WAF, endpoint)"
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query "WebACLs[].Name" --output text
aws ec2 describe-vpc-endpoints --filters "Name=tag:Name,Values=bsiaw-secretsmanager-endpoint" --query "VpcEndpoints[?State!='deleted'].VpcEndpointId" --output text
Write-Host "Srodowisko wylaczone."
Read-Host "Nacisnij Enter, aby zamknac"
