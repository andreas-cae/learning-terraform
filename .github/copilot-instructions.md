# Copilot Cloud Agent Instructions

## Repository Overview

This repository is the companion code for the LinkedIn Learning course **"Learning Terraform"** by Josh Samuelson. It demonstrates how to use Terraform to provision and manage AWS infrastructure as code.

The `main` branch contains the starting/intermediate course code. The repository uses a multi-branch structure where each branch (e.g., `02_03`) corresponds to a specific chapter and video in the course. The `final` branch contains the fully completed code.

## Technology Stack

- **Infrastructure-as-Code tool:** [Terraform](https://developer.hashicorp.com/terraform) (HashiCorp)
- **Cloud provider:** AWS (`hashicorp/aws` provider), region `eu-north-1`
- **Key Terraform Registry modules used:**
  - `terraform-aws-modules/vpc/aws` — VPC creation
  - `terraform-aws-modules/security-group/aws` (v5.3.1) — Security groups
  - `terraform-aws-modules/alb/aws` — Application Load Balancer

## File Structure

| File | Purpose |
|------|---------|
| `providers.tf` | Declares the required `aws` provider and sets the default region (`eu-north-1`) |
| `variables.tf` | Input variables (currently: `instance_type`, default `t3.micro`) |
| `main.tf` | Core infrastructure: AMI data source, VPC, EC2 instance, security group, ALB, target group |
| `outputs.tf` | Output values exposed after `terraform apply` (AMI ID, instance ARN) |

## Infrastructure Summary

The code provisions:
1. **VPC** (`blog_vpc`) — CIDR `10.0.0.0/16`, three public subnets in `eu-north-1a/b/c`.
2. **Security Group** (`blog_sg`) — allows HTTP (80) and HTTPS (443) inbound; all outbound.
3. **EC2 instance** (`blog`) — uses the latest Bitnami Tomcat AMI (`bitnami-tomcat-*-x86_64-hvm-ebs-nami`), placed in the first public subnet, instance type controlled by `var.instance_type`.
4. **Application Load Balancer** (`blog_alb`) — forwards HTTP:80 to a target group.
5. **Target Group + Attachment** — attaches the EC2 instance to the ALB on port 80.

## Working with This Repository

### Prerequisites (not pre-installed — must be set up)

- **Terraform CLI** (any recent version ≥ 1.x). Install via:
  ```bash
  sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt-get install terraform
  ```
- **AWS credentials** — required for `terraform plan` / `terraform apply`. Set via environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or instance profile. Without credentials, `terraform validate` and `terraform fmt` still work locally.

### Common Terraform Commands

```bash
terraform init      # Initialize working directory, download provider/modules
terraform fmt       # Format .tf files in-place (style only, no logic changes)
terraform validate  # Validate configuration syntax (no AWS credentials needed)
terraform plan      # Show execution plan (requires AWS credentials)
terraform apply     # Apply changes to AWS (requires AWS credentials)
terraform destroy   # Destroy all provisioned resources
```

### Linting / Validation (no credentials required)

```bash
terraform fmt -check -recursive   # Check formatting without changing files
terraform validate                 # Syntax and schema validation
```

Always run `terraform fmt` and `terraform validate` after editing `.tf` files to confirm correctness.

> **Note:** `terraform init` must be run before `terraform validate` to download the required provider plugins and modules. Module source downloads require internet access.

### Known Workarounds / Errors

- **`terraform init` module download failures in sandboxed environments:** If the Terraform Registry is unreachable, `terraform validate` will fail with module-not-found errors. Use `terraform fmt -check` for syntax/formatting checks instead, which does not require `terraform init`.
- **No `terraform.tfstate` in repo:** This is intentional for a learning repo. Never commit state files.
- **Commented-out resources:** Several blocks in `main.tf` are intentionally commented out (e.g., NAT gateway, default VPC data source) as they represent progressive course content. Do not uncomment them unless a task explicitly requires it.

## Conventions and Style

- Follow [HashiCorp's Terraform style guide](https://developer.hashicorp.com/terraform/language/style): 2-space indentation, resource naming with underscores, tag blocks aligned.
- Resource names follow the pattern `<service>_<role>` (e.g., `aws_instance.blog`, `aws_lb_target_group.blog-tg`).
- Variables should always include a `description` field.
- Outputs should always expose the minimal necessary information.

## Important Notes

- This repository **does not accept pull requests** (per `CONTRIBUTING.md`). It is a read-only learning reference.
- No CI/CD workflows currently exist in this repository.
- No Terraform backend configuration is present; state is local only.
