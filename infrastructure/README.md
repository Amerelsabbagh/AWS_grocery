<<<<<<< HEAD
# 🏗️ GroceryMate – AWS Terraform Infrastructure![Terraform](https://img.shields.io/badge/Terraform-≥1.5-7B42BC?style=flat&logo=terraform)![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=flat&logo=amazonaws)![Docker](https://img.shields.io/badge/Docker-Container-2496ED?style=flat&logo=docker)![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?style=flat&logo=postgresql)![Region](https://img.shields.io/badge/Region-eu--central--1-orange?style=flat)---## 📌 Table of Contents- [Overview](#overview)- [Architecture Diagram](#architecture-diagram)- [Architecture Overview](#architecture-overview)- [Folder Structure](#folder-structure)- [EC2 Bootstrapping](#ec2-bootstrapping-userdatash)- [Terraform Usage](#terraform-usage)  - [Prerequisites](#1-prerequisites)  - [Configure terraform.tfvars](#2-configure-terraformtfvars)  - [Initialize and Apply](#3-initialize-and-apply)- [Accessing the Application](#accessing-the-application)- [RDS and Data Seeding](#rds-and-data-seeding)- [S3 Avatars Bucket](#s3-avatars-bucket)- [Destroying the Stack](#destroying-the-stack)- [Notes and Future Improvements](#notes-and-future-improvements)---## 🚀 OverviewThis document describes the **GroceryMate AWS infrastructure** managed with Terraform.It lives under the `infrastructure/` folder and covers:- VPC, subnets, and networking- EC2 app server with Docker- RDS PostgreSQL (private subnets)- S3 bucket for user avatars- IAM role and instance profile- EC2 user data bootstrapping (DB seeding + Docker run)---## 🗺️ Architecture Diagram![GroceryMate AWS architecture](architecture.png)---## 🏛️ Architecture Overview- 🔷 **VPC**  - CIDR: `10.0.0.0/16`  - DNS support and hostnames enabled- 🌐 **Subnets**  - Public subnet `10.0.1.0/24` in `eu-central-1a` → EC2 app server  - Private subnet `10.0.2.0/24` in `eu-central-1b` → RDS  - Private subnet `10.0.3.0/24` in `eu-central-1c` → RDS- 🔗 **Networking**  - Internet Gateway (IGW) attached to the VPC  - Public route table: `0.0.0.0/0 → IGW`- 🔒 **Security Groups**  - `ec2_sg`:    - Inbound: SSH `22` from `my_ip`, HTTP `80` and app port `5000` from `0.0.0.0/0`    - Outbound: all traffic  - `rds_sg`:    - Inbound: PostgreSQL `5432` from `ec2_sg` only    - Outbound: all traffic- 🖥️ **EC2 App Server**  - AMI: Amazon Linux 2023 (configurable via `var.my_ami`)  - Instance type: `t3.micro` (configurable)  - Launched in public subnet with a public IP  - IAM instance profile: `grocery-ec2-profile` with `AmazonS3FullAccess`- 🗄️ **RDS PostgreSQL**  - Engine: `postgres`  - Instance class: `db.t3.micro`  - Storage: 20 GB (auto-scales to 100 GB)  - Not publicly accessible  - Deployed across two private subnets via DB subnet group  - Master user: `postgres` / `var.db_password`- 🪣 **S3**  - Bucket: `grocerymate-avatars-70223957`  - Stores avatar images under `avatars/`  - Versioning enabled, public access blocked  - Bucket policy: EC2 IAM role can `ListBucket`, `GetObject`, `PutObject`- 🐳 **App Container**  - Repo: `https://github.com/Amerelsabbagh/AWS_grocery` (branch `version2`)  - Docker image built from `backend/Dockerfile`  - Container listens on port `5000`---## 📁 Folder Structure| File | Purpose ||---|---|| `main.tf` | VPC, subnets, security groups, EC2, RDS, DB subnet group || `variables.tf` | Input variables (region, instance type, CIDRs, DB settings) || `iam-role.tf` | EC2 IAM role and instance profile with S3 access || `s3.tf` | S3 bucket, versioning, public access block, bucket policy || `outputs.tf` | EC2 public IP/DNS and RDS endpoint outputs || `userdata.sh` | EC2 bootstrap script: installs Docker, seeds DB, runs container || `terraform.tfvars` | Environment values (region, key pair, `my_ip`, `db_password`) || `architecture.png` | AWS infrastructure architecture diagram |---## ⚙️ EC2 Bootstrapping (userdata.sh)On first boot, EC2 automatically runs `userdata.sh` which:1. 📋 **Sets up logging** — logs to `/tmp/user-data.log` and `/var/log/user-data.log`2. 📦 **Installs packages** — `git`, `docker`, `postgresql15`, `python3.11`3. 🐳 **Starts Docker** — enables Docker service, adds `ec2-user` to `docker` group4. 📥 **Clones the repo** — clones `version2` branch into `/home/ec2-user/AWS_grocery`5. ⏳ **Waits for RDS** — polls using `RDS_ENDPOINT` until port 5432 is reachable6. 🗄️ **Creates DB and user** — creates `grocerymate_db` and `grocery_user` if missing, grants full privileges7. 📊 **Imports seed data** — imports `sqlite_dump_clean.sql` if no tables exist (idempotent)8. 🚀 **Builds and runs container** — builds image `grocerymate`, starts container with:   - Host networking + restart policy `unless-stopped`   - Env vars: `S3_BUCKET_NAME`, `S3_REGION`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_URI`9. ✅ **Verifies** — runs `SELECT COUNT(*) FROM products` and logs the result---## 🛠️ Terraform Usage### 1. Prerequisites- Terraform `>= 1.5`- AWS credentials configured (`aws configure`)- An existing EC2 key pair in `eu-central-1`### 2. Configure terraform.tfvars```hclaws_region        = "eu-central-1"project_name      = "grocery-app"ec2_instance_type = "t3.micro"key_name          = "your-key-name"my_ip             = "YOUR_PUBLIC_IP/32"db_password       = "your-secure-password"```> Replace `YOUR_PUBLIC_IP/32` with your real IP so you can SSH into the instance.### 3. Initialize and Apply```bashcd infrastructure/terraform initterraform planterraform apply```Terraform will create:- VPC, subnets, IGW, and route table- Security groups for EC2 and RDS- S3 bucket with versioning and bucket policy- IAM role and instance profile- RDS PostgreSQL instance- EC2 app server with user data**Outputs after apply:**| Output | Description ||---|---|| `ec2_public_ip` | Public IP of the EC2 instance || `ec2_public_dns` | Public DNS of the EC2 instance || `rds_endpoint` | RDS PostgreSQL hostname || `rds_port` | RDS port (5432) |---## 🌍 Accessing the ApplicationAfter `terraform apply` completes and user data finishes (takes ~3-5 min):SSH into the instance for debugging:```bashssh -i /path/to/your-key.pem ec2-user@<ec2_public_dns>```Useful commands on EC2:```bash# Check boot logssudo tail -n 100 /var/log/user-data.log# Check running containersdocker ps# Check app logsdocker logs grocerymate-app --tail 100```---## 🗄️ RDS and Data Seeding- RDS is in **private subnets** — not publicly accessible- Only EC2 can reach PostgreSQL on port `5432`- On first boot, user data automatically:  - Creates `grocerymate_db` if missing  - Creates `grocery_user` with password `grocery_test`  - Imports `sqlite_dump_clean.sql` if no tables existManual inspection from EC2:```bashexport PGPASSWORD='grocery_test'psql -h <rds_endpoint> -U grocery_user -d grocerymate_db -c "\dt"psql -h <rds_endpoint> -U grocery_user -d grocerymate_db -c "SELECT COUNT(*) FROM products;"```---## 🪣 S3 Avatars Bucket- Bucket: `grocerymate-avatars-70223957`- Default avatar: `avatars/user_default.png`- Versioning enabled, public access blocked- EC2 IAM role permissions:  - `s3:ListBucket` on the bucket  - `s3:GetObject` and `s3:PutObject` on `avatars/*`---## 💣 Destroying the Stack```bashterraform destroy```> ⚠️ **Warning:** This destroys **all resources** including RDS data and S3 objects. Back up important data first.---## 📝 Notes and Future Improvements- Consider moving DB migrations and seeding into the app (Flask-Migrate) to reduce `userdata.sh` complexity- Add health checks for EC2, Docker container, and RDS- Add an ALB in front of EC2 for HTTP/HTTPS on ports 80/443- Use AWS Secrets Manager instead of `terraform.tfvars` for `db_password`
=======
\# GroceryMate – AWS Terraform Infrastructure



This document describes the GroceryMate AWS infrastructure managed with Terraform. It lives under the `infrastructure/` folder and focuses on VPC, networking, EC2, RDS, S3, IAM, and the EC2 user data bootstrapping.



\---



\## Architecture Diagram



![GroceryMate AWS architecture](architecture.png)



\---



\## Architecture Overview



\- \*\*VPC\*\*

&#x20;   - CIDR: `10.0.0.0/16`

&#x20;   - DNS support and hostnames enabled.



\- \*\*Subnets\*\*

&#x20; - Public subnet `10.0.1.0/24` in `eu-central-1a` for the EC2 app server.

&#x20; - Private subnets `10.0.2.0/24` (`eu-central-1b`) and `10.0.3.0/24` (`eu-central-1c`) for RDS.



\- \*\*Networking\*\*

&#x20; - Internet Gateway (IGW) attached to the VPC.

&#x20; - Public route table with `0.0.0.0/0 -> IGW` associated with the public subnet.



\- \*\*Security Groups\*\*

&#x20; - `ec2\_sg`:

&#x20;   - Inbound: SSH 22 from `my\_ip`, HTTP 80 and app port 5000 from `0.0.0.0/0`.

&#x20;   - Outbound: all (`0.0.0.0/0`).

&#x20; - `rds\_sg`:

&#x20;   - Inbound: PostgreSQL 5432 from `ec2\_sg`.

&#x20;   - Outbound: all.



\- \*\*EC2 App Server\*\*

&#x20; - AMI: configurable via `var.my\_ami` (default Amazon Linux 2023).

&#x20; - Instance type: `var.ec2\_instance\_type` (default `t3.micro`).

&#x20; - Launched in the public subnet with a public IP.

&#x20; - IAM instance profile `grocery-ec2-profile` with role `grocery-ec2-role` and `AmazonS3FullAccess`.



\- \*\*RDS PostgreSQL\*\*

&#x20; - Engine: `postgres`.

&#x20; - Instance class: `db.t3.micro`.

&#x20; - Storage: 20 GB (auto-scale up to 100 GB).

&#x20; - Not publicly accessible.

&#x20; - Deployed in a DB subnet group across the two private subnets.

&#x20; - Master user: `var.db\_username` (default `postgres`) with password `var.db\_password`.



\- \*\*S3\*\*

&#x20; - Bucket: `grocerymate-avatars-70223957`.

&#x20; - Stores avatar images under the `avatars/` prefix.

&#x20; - Versioning enabled; public access blocked.

&#x20; - Bucket policy allows only the EC2 IAM role to:

&#x20;   - `s3:ListBucket` on the bucket.

&#x20;   - `s3:GetObject` / `s3:PutObject` on `avatars/\*`.



\- \*\*App Container\*\*

&#x20; - Repository: `https://github.com/Amerelsabbagh/AWS\_grocery` (branch `version2`).

&#x20; - Docker image built from `backend/Dockerfile`.

&#x20; - Container listens on port 5000.

&#x20; - Uses RDS and S3 via environment variables.



\---



\## Folder Structure



Key files inside the `infrastructure/` directory:



| File | Purpose |

|---|---|

| `main.tf` | VPC, subnets, security groups, EC2, RDS, DB subnet group |

| `variables.tf` | Input variables (region, instance type, CIDRs, DB settings, etc.) |

| `iam-role.tf` | EC2 IAM role and instance profile with S3 access |

| `s3.tf` | S3 bucket, versioning, public access block, bucket policy |

| `outputs.tf` | EC2 public IP/DNS and RDS endpoint outputs |

| `userdata.sh` | EC2 bootstrap script: installs Docker, clones repo, seeds DB, runs container |

| `terraform.tfvars` | Environment-specific values (region, key pair, `my\_ip`, `db\_password`, etc.) |

| `architecture.png` | Architecture diagram of the AWS infrastructure |



\---



\## EC2 Bootstrapping (userdata.sh)



On first boot, the EC2 instance runs `userdata.sh` which:



1\. \*\*Sets up logging\*\* — logs to `/tmp/user-data.log` and `/var/log/user-data.log`.

2\. \*\*Installs packages\*\* — `git`, `docker`, `postgresql15`, `python3.11`, `python3.11-pip`.

3\. \*\*Starts Docker\*\* — enables and starts the Docker service, adds `ec2-user` to the `docker` group.

4\. \*\*Clones the repository\*\* — clones `version2` branch of `AWS\_grocery` into `/home/ec2-user/AWS\_grocery`.

5\. \*\*Waits for RDS\*\* — polls using `RDS\_ENDPOINT`, `RDS\_MASTER\_USER`, `RDS\_MASTER\_PASSWORD` passed from Terraform until RDS is reachable on port 5432.

6\. \*\*Creates DB and user\*\* — creates `grocerymate\_db` if missing, creates or updates `grocery\_user` with password `grocery\_test`, grants full privileges on the `public` schema.

7\. \*\*Imports seed data\*\* — if the `public` schema has zero tables, imports `sqlite\_dump\_clean.sql` into `grocerymate\_db` as `grocery\_user`. Skips import if tables already exist (idempotent).

8\. \*\*Builds and runs Docker container\*\* — builds image `grocerymate` from `backend/`, removes any existing container named `grocerymate-app`, runs with host networking, restart policy `unless-stopped`, and the following environment variables:

&#x20;  - `S3\_BUCKET\_NAME`, `S3\_REGION`, `USE\_S3\_STORAGE`

&#x20;  - `POSTGRES\_USER`, `POSTGRES\_PASSWORD`, `POSTGRES\_DB`, `POSTGRES\_HOST`, `POSTGRES\_URI`

9\. \*\*Verification\*\* — runs `SELECT COUNT(\*) FROM products` as `grocery\_user` and logs the result.



\---



\## Terraform Usage



\### 1. Prerequisites



\- Terraform >= 1.5.

\- AWS credentials configured (e.g. `aws configure`).

\- An existing EC2 key pair in the target region.



\### 2. Configure terraform.tfvars



```hcl

aws\_region        = "eu-central-1"

project\_name      = "grocery-app"

ec2\_instance\_type = "t3.micro"

key\_name          = "your-key-name"

my\_ip             = "YOUR\_PUBLIC\_IP/32"

db\_password       = "your-secure-password"

```



Replace `YOUR\_PUBLIC\_IP/32` with your actual IP so you can SSH into the instance.



\### 3. Initialize and apply



From the `infrastructure/` directory:



```bash

terraform init

terraform plan

terraform apply

```



Terraform will create:



\- VPC, subnets, IGW, and route table.

\- Security groups for EC2 and RDS.

\- S3 bucket, versioning, public access block, and bucket policy.

\- IAM role and instance profile for EC2 with S3 access.

\- RDS PostgreSQL instance.

\- EC2 app server with user data.



At the end, Terraform outputs:



\- `ec2\_public\_ip`

\- `ec2\_public\_dns`

\- `rds\_endpoint`

\- `rds\_port`



\---



\## Accessing the Application



After `terraform apply` completes and user data finishes, the app is available at:



>>>>>>> 3de716bb540288f5799b50251f7a24fcd651a898
