# URL Shortener V2 🔗

A URL shortener API deployed on AWS ECS Fargate, built with
Terraform and Node.js.

## ✨ Features

- Shorten any long URL to a short code
- Instant redirects via HTTP 301
- Visit counter per short code
- Beautiful dark UI
- Fully serverless on AWS Fargate

## 🏗️ Architecture

User → ALB → ECS Fargate (private subnet) → DynamoDB

- **VPC** — public and private subnets
- **ALB** — HTTP load balancer
- **ECS Fargate** — serverless containers
- **ECR** — Docker image registry
- **DynamoDB** — stores URL mappings
- **CloudWatch** — container logs
- **IAM** — least privilege roles

## 📁 Project Structure

url-shortener-v2/
├── app/
│   ├── server.js       # Express app (routes + HTML UI)
│   ├── index.js        # Entry point
│   └── package.json    # Dependencies
├── terraform/
│   ├── backend.tf      # S3 state + DynamoDB locking
│   ├── main.tf         # Wires all modules together
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # Output values
│   └── modules/
│       ├── vpc/        # Networking
│       ├── ecr/        # Container registry
│       ├── database/   # DynamoDB
│       ├── iam/        # Roles + permissions
│       ├── security/   # Security groups
│       ├── alb/        # Load balancer
│       ├── ecs/        # Fargate cluster + service
│       └── github-actions/ # OIDC for CI/CD
├── .github/
│   └── workflows/
│       └── ci.yml      # GitHub Actions CI
├── Dockerfile          # Multi-stage build
└── .dockerignore

## 🚀 Getting Started

### Prerequisites

- [Node.js 20+](https://nodejs.org/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Terraform 1.5+](https://www.terraform.io/)
- [AWS CLI](https://aws.amazon.com/cli/)

### Run locally

```bash
cd app
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000)

> Note: URL shortening errors locally (no DynamoDB).
> `/health` works fine.

## 🏗️ Deploy to AWS

### Step 1: Bootstrap Terraform backend

Create once in your AWS account:

```bash
# S3 bucket for state
aws s3api create-bucket \
  --bucket YOUR-BUCKET-NAME \
  --region eu-west-2 \
  --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-bucket-versioning \
  --bucket YOUR-BUCKET-NAME \
  --versioning-configuration Status=Enabled

# DynamoDB lock table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-2
```

Update `terraform/backend.tf` with your bucket name.

### Step 2: Deploy infrastructure

```bash
cd terraform
terraform init

terraform apply \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=url-shortener-v2"
```

### Step 3: Push Docker image

```bash
# Authenticate with ECR
aws ecr get-login-password --region eu-west-2 | \
  docker login --username AWS --password-stdin YOUR_ECR_URL

# Build for linux/amd64 (required for Fargate)
docker build --platform linux/amd64 -t url-shortener-v2 .

# Tag and push
docker tag url-shortener-v2:latest YOUR_ECR_URL:latest
docker push YOUR_ECR_URL:latest
```

### Step 4: Force new deployment

```bash
aws ecs update-service \
  --cluster url-shortener-v2-cluster \
  --service url-shortener-v2-service \
  --force-new-deployment \
  --region eu-west-2
```

## 🗑️ Destroy infrastructure

```bash
cd terraform
terraform destroy \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=url-shortener-v2"
```

## 🔐 Security

- **OIDC** — no long-lived AWS credentials
- **IAM least privilege** — app only accesses its own table
- **Private subnets** — containers not reachable from internet
- **Security groups** — ECS only accepts traffic from ALB

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| App | Node.js + Express |
| Short codes | nanoid |
| Container | Docker (multi-stage, Alpine) |
| Registry | Amazon ECR |
| Compute | AWS ECS Fargate |
| Database | Amazon DynamoDB |
| Networking | AWS VPC + ALB |
| IaC | Terraform (modular) |
| State | S3 + DynamoDB locking |
| CI | GitHub Actions |
| Auth | OIDC (no secrets) |
| Logs | CloudWatch |
