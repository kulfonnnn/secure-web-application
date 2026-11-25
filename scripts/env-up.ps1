# Wlacza srodowisko: RDS, potem Terraform (ElastiCache, ALB, WAF, endpoint), na koncu EC2.
$ErrorActionPreference = "Continue"
$infra = Join-Path $PSScriptRoot "..\iac-infrastructure"

# 1. Uruchomienie RDS (bez czekania na dostepnosc)
aws rds start-db-instance --db-instance-identifier bsiaw-db | Out-Null
Write-Host "RDS: uruchamianie"

# 2. Terraform bezposrednio w terminalu (ewentualne bledy nie przerywaja skryptu)
Push-Location $infra
terraform apply -auto-approve
Pop-Location

# 3. Uruchomienie zatrzymanych instancji EC2 (po Terraformie, bo cache ma nowy adres)
$ids = aws ec2 describe-instances --filters "Name=tag:Project,Values=bsiaw" "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text

if ($ids -and $ids -ne "None") {
    aws ec2 start-instances --instance-ids $ids.Split() | Out-Null
    Write-Host "EC2: uruchamianie $ids"
}

# 4. Oczekiwanie na dwa zdrowe cele w Target Group (maksymalnie ok. 10 minut)
$tg = aws elbv2 describe-target-groups --names bsiaw-app --query "TargetGroups[0].TargetGroupArn" --output text

if ($tg -and $tg -ne "None") {
    for ($i = 0; $i -lt 30; $i++) {
        $states = (aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].TargetHealth.State" --output text) -split "\s+"

        if ($states.Count -ge 2 -and -not ($states | Where-Object { $_ -ne "healthy" })) { break }

        Start-Sleep -Seconds 20
    }
    Write-Host "Cele w Target Group: $states"
}
else {
    Write-Host "Brak Target Group bsiaw-app (ALB nie istnieje) - pomijam oczekiwanie."
}

Write-Host "Srodowisko: https://app.securewebapp.click"
Read-Host "Nacisnij Enter, aby zamknac"