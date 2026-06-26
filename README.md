# Think Cricket — AWS Infrastructure

Terraform infrastructure for the Think Cricket backend, running on AWS EC2.

Live app: **https://think-cricket-frontend.vercel.app/**

---

## Architecture

```
User → Vercel (Next.js frontend)
           ↓ server-side proxy (/api/*)
       AWS EC2 t3.micro (Spring Boot API)  ← ap-south-1 (Mumbai)
           ↓
       Supabase (PostgreSQL)
```

| Layer | Technology | Hosting |
|---|---|---|
| Frontend | Next.js | Vercel (free) |
| Backend API | Spring Boot (Java 17) | AWS EC2 t3.micro |
| Database | PostgreSQL | Supabase (free tier, persistent) |
| Jar storage | AWS S3 | `think-cricket-artifacts` bucket |
| Terraform state | AWS S3 + DynamoDB | Remote backend with state locking |

---

## Repository Structure

```
.
├── main.tf                       # Root module — wires networking + EC2
├── variables.tf                  # All input variables
├── outputs.tf                    # EC2 public IP, instance ID
├── backend.tf                    # S3 remote state + DynamoDB lock table
├── terraform.tfvars.example      # Template — copy to terraform.tfvars locally
├── modules/
│   ├── networking/               # VPC, subnet, internet gateway, route table
│   └── ec2/                      # EC2 instance, security group, IAM role
└── scripts/
    └── startup.sh                # user_data: pulls jar from S3, starts systemd service
```

---

## How Deployment Works

1. The `Think_Cricket` build repo compiles the Spring Boot app and uploads `app.jar` to S3
2. A push to `main` in this repo triggers `terraform apply`
3. Terraform provisions the EC2 instance; the `startup.sh` user_data script runs on first boot:
   - Installs Java 17
   - Downloads the jar from S3 using the instance's IAM role (no credentials stored)
   - Reads DB credentials from SSM Parameter Store
   - Starts the app as a systemd service on port 8080
4. The Vercel frontend proxies all `/api/*` requests to the EC2 public IP via `BACKEND_URL`

No SSH keys configured — use **AWS Systems Manager Session Manager** for console access if needed.

---

## GitHub Actions Workflows

| Trigger | Action |
|---|---|
| Push to `main` | `terraform apply` — provisions or updates infrastructure |
| Pull request | `terraform plan` — shows what would change, no apply |
| Manual (`workflow_dispatch`) | `terraform destroy` — tears everything down |

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `TF_VAR_jar_s3_bucket` | S3 bucket name holding the Spring Boot jar |

---

## Credentials and Secrets

Nothing sensitive is stored in this repo.

| What | Where it lives |
|---|---|
| AWS access keys | GitHub Actions secrets |
| Terraform state | S3 bucket (`think-cricket-tfstate`) |
| State lock | DynamoDB table (`think-cricket-tf-locks`) |
| DB password | AWS SSM Parameter Store (`/think-cricket/*`) |
| Local var values | `terraform.tfvars` — git-ignored, never committed |

---

## After Each Reprovisioning

The EC2 instance gets a new public IP each time Terraform destroys and recreates it. After `terraform apply` completes:

1. Note the `instance_public_ip` in the workflow output
2. Vercel Dashboard → Think Cricket project → Settings → Environment Variables
3. Update `BACKEND_URL` to `http://<new-ip>:8080`
4. Redeploy on Vercel

---

## Local Setup

> Requires Terraform CLI and AWS CLI configured locally.

```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

---

## Bootstrap (One-Time)

Before the first deploy, the S3 state bucket, DynamoDB lock table, S3 artifact bucket, and SSM parameters must exist. These are created via CloudFormation — see the `cloudformation/` directory in the main `Think_Cricket` repo.
