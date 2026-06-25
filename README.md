# Think Cricket — AWS Terraform

Infrastructure-as-Code for the Think Cricket app. Manages the AWS backend compute layer only. Frontend and database are hosted on separate always-free services and are not managed here.

---

## Architecture

| Layer | Service | Managed Here |
|---|---|---|
| Frontend | Vercel | No — deploy via Vercel GitHub integration |
| Database | Supabase (PostgreSQL) | No — always-free, persistent |
| Backend | AWS EC2 t3.micro | Yes |

The EC2 instance is the only resource that costs money when running. Destroy it when not needed and re-create it when required for demos or testing. The database on Supabase persists across destroy/apply cycles so no data is lost.

---

## Workflow

```bash
# Bring everything up (~2-3 minutes to be live)
terraform apply

# Tear everything down (stops billing)
terraform destroy
```

On apply, the EC2 instance boots and runs a `user_data` startup script that pulls the latest Spring Boot jar and starts the application automatically. No manual SSH required.

---

## Credentials and Secrets

Nothing secret is stored in this repo. All sensitive values are injected at runtime:

| What | Where it lives |
|---|---|
| AWS access keys | GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |
| Terraform state | S3 bucket (remote backend) |
| State lock | DynamoDB table |
| DB password / app secrets | AWS Secrets Manager or SSM Parameter Store, referenced by ARN |
| Variable values | `terraform.tfvars` — local only, never committed |

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in values before running locally.

---

## Repo Structure (Planned)

```
.
├── main.tf                       # Root module — wires everything together
├── variables.tf                  # Variable definitions (no values)
├── outputs.tf                    # EC2 public IP, DNS, etc.
├── terraform.tfvars.example      # Template — copy to terraform.tfvars locally
├── backend.tf                    # S3 remote state config
├── modules/
│   ├── ec2/                      # EC2 instance, security group, key pair
│   └── networking/               # VPC, subnet, internet gateway, route table
├── scripts/
│   └── startup.sh                # user_data script — pulls jar, starts Spring Boot
└── .github/
    └── workflows/
        └── terraform.yml         # CI: plan on PR, apply on merge to main
```

---

## Backend App

- **Repo:** Think_Cricket (Spring Boot 4.0.2 / Java 17)
- **Database:** PostgreSQL via Supabase (connection string injected as env var on EC2 boot)
- **Jar delivery:** Built via GitHub Actions on the backend repo, uploaded to S3, pulled by `startup.sh` on EC2 boot

---

## Prerequisites

- AWS account with free tier active
- Terraform CLI installed (`>= 1.5`)
- AWS CLI configured locally OR environment variables set
- S3 bucket and DynamoDB table created for remote state (one-time manual setup)
- Supabase project created with PostgreSQL connection string ready

---

## Local Setup

```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

---

## .gitignore

```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
crash.log
```

`terraform.tfvars.example` is committed. `terraform.tfvars` is not.