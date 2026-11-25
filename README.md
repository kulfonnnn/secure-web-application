# Secure Web Application

A web application developed as part of a university project focused on web application security, cloud infrastructure and secure deployment.

The project combines a Django application with an AWS cloud environment. Its main goals are to develop application functionality, deploy it using modern infrastructure practices and apply security controls at both application and infrastructure levels.

The project is developed by a team of **three members**, with **Mikołaj as the Team Leader**. Every member of the team focuses on different topics.


*Note: The current version is available in the `cloudfront-final` branch, as we are waiting for AWS account verification before running the final tests and merging it into `main`.*

## Cloud Architecture

The application is designed to run on AWS using a private network architecture. Public access is intended to be handled through CloudFront and an Application Load Balancer, while application instances and data services remain in private subnets.

<img width="1595" height="891" alt="awsinfrastructure drawio" src="https://github.com/user-attachments/assets/38fcda78-63fd-4741-8902-d03890924bf7" />


Main infrastructure components:

- **Amazon VPC** – isolated network with public and private subnets across two Availability Zones.
- **Amazon CloudFront and AWS WAF** – planned external traffic entry point and web application protection.
- **Application Load Balancer** – distributes incoming traffic between application instances.
- **Amazon EC2** – runs the Django application in Docker containers.
- **Amazon RDS** – PostgreSQL database.
- **Amazon ElastiCache** – Valkey cache used for rate-limiting counters.
- **Amazon S3** – application deployment files and user-uploaded content.
- **AWS Secrets Manager and IAM** – secret storage and access control.
- **Amazon Route 53 and ACM** – DNS management and TLS certificates.
- **Amazon CloudWatch and SNS** – monitoring and notifications.

*Note: The CloudFront deployment is currently affected by an AWS account verification restriction.*


## Technology Stack

| Area | Technologies |
|---|---|
| Backend | Python, Django |
| Database | PostgreSQL |
| Cache | Valkey |
| Containers | Docker, Docker Compose |
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Web server | Gunicorn |
| Version control | Git, GitHub |
| Automation | PowerShell |

## Application Features

The application is built with Django and PostgreSQL. Its functionality includes:

- User accounts and authentication.
- Login and registration.
- Database-backed application functionality.
- Additional interactive features developed as part of the project.

The application is containerized with Docker to provide a consistent development and deployment environment.

## Project Progress

| Area | Status |
|---|---|
| Django application and database | Implemented |
| Docker-based local environment | Implemented |
| AWS network and infrastructure | Implemented |
| Database and cache integration | Implemented |
| Secrets management and IAM | Implemented |
| Infrastructure lifecycle scripts | Implemented |
| CloudFront deployment | Pending AWS account verification |
| CI/CD  | Planned |
| Hardening| Planned |
| Pentesting | Planned |

Future work will focus on CI/CD automation, security testing, application hardening and infrastructure security improvements.

## Local Development

### Requirements

- Git
- Docker
- Docker Compose

### Clone the repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### Configure environment variables

Prepare the required environment configuration using the example configuration files available in the repository.

Do not commit passwords, secret keys or other sensitive values.

### Start the application

```bash
docker compose up --build -d
```

### Database migrations

Run Django migrations inside the application container:

```bash
docker compose exec <django-service> python manage.py migrate
```

Create an administrator account if needed:

```bash
docker compose exec <django-service> python manage.py createsuperuser
```

The application should be available at the local address configured in Docker Compose.

### Useful commands

```bash
# View running containers
docker compose ps

# View application logs
docker compose logs -f

# Stop containers
docker compose down

# Stop containers and remove volumes
docker compose down -v
```

The last command removes local Docker volumes, including persistent database data. Use it with care.

## AWS Infrastructure – Terraform

The AWS infrastructure is managed using Terraform.

### Requirements

- AWS CLI
- Terraform
- PowerShell (for lifecycle scripts)
- AWS authentication with appropriate permissions

### Initialize Terraform

Run the following commands from the infrastructure directory:

```powershell
cd iac-infrastructure

terraform init
terraform validate
terraform plan
```

Review the planned changes before applying them.

```powershell
terraform apply
```

To remove Terraform-managed resources:

```powershell
terraform destroy
```

**Warning:** Terraform operations can create billable AWS resources or delete existing infrastructure and data. Always review the plan before applying changes.

Terraform state is stored remotely in Amazon S3. It may contain sensitive infrastructure information and must be protected.

## AWS Environment Management

PowerShell scripts are provided to manage the AWS environment and reduce costs when it is not in use.

### Start the environment

```powershell
.\env-up.ps1
```

The script starts the database, recreates selected infrastructure components through Terraform and starts the EC2 instances.

### Stop the environment

```powershell
.\env-down.ps1
```

The script stops EC2 and RDS instances and removes selected resources that would otherwise generate ongoing costs.

Some resources are retained to make the next startup easier and preserve configuration and data.

The scripts require valid AWS CLI authentication and access to the appropriate AWS account.

## Security

Security is considered throughout the application and infrastructure design.

Implemented measures include:

- Private subnets for application and database instances.
- Security Groups restricting network traffic between components.
- IAM roles instead of long-term AWS access keys for EC2.
- AWS Secrets Manager for application secrets.
- Encrypted storage and private S3 buckets.
- HTTPS and TLS for external and internal service communication.
- Production-specific Django configuration.
- AWS WAF rules prepared for web application protection.

The infrastructure is managed as code using Terraform to support repeatable deployments and consistent configuration.


