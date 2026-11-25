# Wlacza srodowisko: RDS, potem Terraform (ElastiCache, ALB, WAF, endpoint), na koncu EC2.
$ErrorActionPreference = "Stop"
$infra = Join-Path $PSScriptRoot "..\iac-infrastructure"

# 1. Uruchomienie RDS i oczekiwanie na dostepnosc
aws rds start-db-instance --db-instance-identifier bsiaw-db | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Nie udalo sie uruchomic RDS." }

aws rds wait db-instance-available --db-instance-identifier bsiaw-db
if ($LASTEXITCODE -ne 0) { throw "RDS nie osiagnal stanu available." }

Write-Host "RDS: dostepny"

# 2. Uruchomienie Terraform w osobnym procesie (bez oczekiwania na zakonczenie)
$terraform = Start-Process -FilePath "terraform" `
    -ArgumentList "apply -auto-approve" `
    -WorkingDirectory $infra `
    -PassThru

Write-Host "Terraform: uruchomiony w tle (PID: $($terraform.Id))"

# 3. Uruchomienie zatrzymanych instancji EC2
$ids = aws ec2 describe-instances --filters "Name=tag:Project,Values=bsiaw" "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text
if ($LASTEXITCODE -ne 0) { throw "Nie udalo sie pobrac listy instancji EC2." }

if ($ids -and $ids -ne "None") {
    aws ec2 start-instances --instance-ids $ids.Split() | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Nie udalo sie uruchomic instancji EC2." }

    Write-Host "EC2: uruchamianie $ids"
}

# 4. Oczekiwanie na dwa zdrowe cele w Target Group (maksymalnie ok. 10 minut)
$tg = aws elbv2 describe-target-groups --names bsiaw-app --query "TargetGroups[0].TargetGroupArn" --output text
if ($LASTEXITCODE -ne 0 -or -not $tg -or $tg -eq "None") {
    throw "Nie udalo sie pobrac Target Group bsiaw-app."
}

$healthy = $false

for ($i = 0; $i -lt 30; $i++) {
    $states = (aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].TargetHealth.State" --output text) -split "\s+"

    if ($LASTEXITCODE -ne 0) {
        throw "Nie udalo sie sprawdzic stanu celow Target Group."
    }

    if ($states.Count -ge 2 -and -not ($states | Where-Object { $_ -ne "healthy" })) {
        $healthy = $true
        break
    }

    Start-Sleep -Seconds 20
}

Write-Host "Cele w Target Group: $states"

if (-not $healthy) {
    throw "Cele Target Group nie osiagnely stanu healthy w wyznaczonym czasie."
}

Write-Host "Srodowisko dostepne: https://app.securewebapp.click"