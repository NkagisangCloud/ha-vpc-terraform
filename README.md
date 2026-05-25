# High-Availability AWS VPC Architecture with Terraform

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)
![Status](https://img.shields.io/badge/Status-Complete-green)

## Project Overview
A production-grade three-tier high-availability VPC architecture deployed on AWS using Terraform as Infrastructure as Code. This project demonstrates real-world cloud engineering practices including network isolation, security group chaining, remote state management, and zero-trust instance access.

## Architecture
Internet
                        |
           Application Load Balancer
            (Public — spans 2 AZs)
                /              \
       Web Server 1        Web Server 2
       (AZ1 - Public)      (AZ2 - Public)
                \              /
       App Server 1        App Server 2
       (AZ1 - Private)     (AZ2 - Private)
                \              /
           RDS MySQL 8.0 (Private DB Subnet)
               (No public accessibility)
## Infrastructure Components

### Networking
| Resource | Details |
|---|---|
| VPC | 10.0.0.0/16 |
| Public Subnets | 10.0.1.0/24 (AZ1), 10.0.2.0/24 (AZ2) |
| Private App Subnets | 10.0.3.0/24 (AZ1), 10.0.4.0/24 (AZ2) |
| Private DB Subnets | 10.0.5.0/24 (AZ1), 10.0.6.0/24 (AZ2) |
| Internet Gateway | Public internet access for web tier |
| NAT Gateway | Outbound internet for private subnets |

### Compute & Load Balancing
| Resource | Details |
|---|---|
| Web Servers | 2x EC2 t3.micro across 2 AZs |
| App Servers | 2x EC2 t3.micro in private subnets |
| Application Load Balancer | Distributes traffic across both web servers |
| Target Group | Health checks every 30 seconds |

### Database
| Resource | Details |
|---|---|
| Engine | MySQL 8.0 |
| Instance | db.t3.micro |
| Accessibility | Private only (no public access) |
| Subnet | Isolated DB subnet — no internet route |

### Security
| Layer | Implementation |
|---|---|
| Instance access | AWS SSM Session Manager — no port 22 exposed |
| Web tier | ALB Security Group → Web Security Group |
| App tier | Accepts traffic from Web SG only |
| DB tier | Accepts traffic from App SG only |
| Subnet level | Network ACLs with ephemeral port rules |
| State file | S3 encryption + public access blocked |

### State Management
| Resource | Purpose |
|---|---|
| S3 Bucket | Stores terraform.tfstate with versioning |
| DynamoDB Table | State locking — prevents concurrent applies |

## Key Concepts Demonstrated
- High Availability across multiple Availability Zones
- Three-tier network architecture (public/private/database)
- Infrastructure as Code with Terraform
- Security Group chaining pattern
- Stateful vs stateless firewalls (Security Groups vs NACLs)
- Bastion-less access via AWS SSM Session Manager
- NAT Gateway for private subnet outbound internet access
- Remote state management with S3 backend and DynamoDB locking
- Bootstrap pattern for Terraform backend initialisation
- Principle of least privilege for IAM

## What This Proves in Production

### High Availability
The ALB distributes traffic across web servers in AZ1 and AZ2. If one AZ goes down, the other continues serving traffic automatically.

### Network Isolation
Database servers have zero internet route — not just blocked, completely unreachable. Even if compromised, the DB cannot phone home.

### Security Group Chaining
Each tier only accepts traffic from the security group directly above it — not IP ranges. A spoofed IP cannot bypass this.

### Zero Trust Access
No SSH port 22 is exposed anywhere. All instance access goes through AWS SSM Session Manager which provides full audit logging of every session.

## Prerequisites
- AWS Account with IAM user and programmatic access
- Terraform >= 1.0
- AWS CLI configured
- SSM Session Manager plugin installed

## Project Structure
## Usage

### 1. Clone the repository
```bash
git clone https://github.com/NkagisangCloud/ha-vpc-terraform.git
cd ha-vpc-terraform
```

### 2. Create your terraform.tfvars
```hcl
my_ip       = "your-public-ip"
db_password = "your-secure-password"
```

### 3. Create S3 backend (one time only)
```bash
aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

### 4. Update backend.tf with your bucket name
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "ha-vpc/terraform.tfstate"
  region         = "us-east-1"
  use_lockfile   = true
  encrypt        = true
}
```

### 5. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 6. Access instances securely via SSM
```bash
aws ssm start-session --target <instance-id>
```

### 7. Test the Load Balancer
```bash
for i in 1 2 3 4; do curl http://<alb-dns-name>; echo; done
```

### 8. Destroy when done
```bash
terraform destroy
```

## Cost Considerations
| Resource | Cost |
|---|---|
| VPC, Subnets, Route Tables | Free |
| EC2 t3.micro | Free tier (750hrs/month) |
| RDS db.t3.micro | Free tier (750hrs/month) |
| S3, DynamoDB | Free tier |
| NAT Gateway | ~$0.045/hr ⚠️ |
| ALB | ~$0.008/hr ⚠️ |

> Always run `terraform destroy` after testing to avoid unexpected charges.

## Author
**Nkagisang Matshego**
Cloud & DevOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://www.linkedin.com/in/nkagisang-matshego-214658323)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?logo=github)](https://github.com/NkagisangCloud)
