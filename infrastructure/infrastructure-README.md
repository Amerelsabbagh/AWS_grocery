# GroceryMate – AWS Terraform Infrastructure

This document describes the GroceryMate AWS infrastructure managed with Terraform. It lives under the `infrastructure/` folder and focuses on VPC, networking, EC2, RDS, S3, IAM, and the EC2 user data bootstrapping.

\---

## Architecture Overview

* **VPC**

  * CIDR: `10.0.0.0/16`.
  * DNS support and hostnames enabled.
* **Subnets**

  * Public subnet `10.0.1.0/24` in `eu-central-1a` for the EC2 app server.
  * Private subnets `10.0.2.0/24` (eu-central-1b) and `10.0.3.0/24` (eu-central-1c) for RDS.
* **Networking**

  * Internet Gateway (IGW) attached to the VPC.
  * Public route table with `0.0.0.0/0 -> IGW` associated with the public subnet.
* **Security Groups**

  * `ec2\\\_sg`:

    * Inbound: SSH 22 from `my\\\_ip`, HTTP 80 and app port 5000 from `0.0.0.0/0`.
    * Outbound: all (`0.0.0.0/0`).
  * `rds\\\_sg`:

    * Inbound PostgreSQL 5432 from `ec2\\\_sg`.
    * Outbound: all.
* **EC2 App Server**

  * AMI: configurable via `var.my\\\_ami` (default Amazon Linux 2023).
  * Instance type: `var.ec2\\\_instance\\\_type` (default `t3.micro`).
  * Launched in the public subnet with a public IP.
  * IAM instance profile `grocery-ec2-profile` with role `grocery-ec2-role` and `AmazonS3FullAccess`.
* **RDS PostgreSQL**

  * Engine: `postgres`.
  * Instance class: `db.t3.micro`.
  * Storage: 20 GB (auto-scale up to 100 GB).
  * Not publicly accessible.
  * Deployed in a DB subnet group across the two private subnets.
  * Master user: `var.db\\\_username` (default `postgres`) with password `var.db\\\_password`.
* **S3**

  * Bucket: `grocerymate-avatars-70223957`.
  * Stores avatar images under the `avatars/` prefix.
  * Versioning enabled.
  * Public access blocked.
  * Bucket policy allows the EC2 IAM role to `ListBucket`, `GetObject`, and `PutObject` for `avatars/\\\*`.
* **App Container**

  * Repository: `https://github.com/Amerelsabbagh/AWS\\\_grocery` (branch `version2`).
  * Docker image built from `backend/Dockerfile`.
  * Container listens on port 5000.
  * Uses RDS and S3 via environment variables.

\---

## Folder Structure (infrastructure)

Inside the `infrastructure/` directory:

* `main.tf` – VPC, subnets, security groups, EC2, RDS, DB subnet group.
* `variables.tf` – Input variables (region, instance type, CIDRs, DB settings, etc.).
* `iam-role.tf` – EC2 IAM role and instance profile with S3 access.
* `s3.tf` – S3 bucket, versioning, public access block, bucket policy.
* `outputs.tf` – EC2 public IP / DNS and RDS endpoint outputs.
* `userdata.sh` – EC2 bootstrap script (installs Docker, clones repo, seeds DB, runs container).
* `terraform.tfvars` – Environment-specific values (region, key pair, `my\\\_ip`, `db\\\_password`, etc.).

\---

## EC2 Bootstrapping (userdata.sh)

On first boot, the EC2 instance runs `userdata.sh` which:

1. **Sets up logging**

   * Logs to `/tmp/user-data.log` and `/var/log/user-data.log`.
2. **Installs packages**

   * `git`, `docker`, `postgresql15`, `python3.11`, `python3.11-pip`.
3. **Starts Docker**

   * Enables and starts the Docker service.
   * Adds `ec2-user` to the `docker` group.
4. **Clones application repository**

   * Clones `version2` branch of `AWS\\\_grocery` into `/home/ec2-user/AWS\\\_grocery`.
   * Verifies `sqlite\\\_dump\\\_clean.sql` exists at `backend/app/sqlite\\\_dump\\\_clean.sql`.
5. **Waits for RDS**

   * Uses `RDS\\\_ENDPOINT`, `RDS\\\_MASTER\\\_USER`, `RDS\\\_MASTER\\\_PASSWORD` passed from Terraform.
   * Polls until RDS is reachable on port 5432.
6. **Creates / updates DB and user**

   * Creates `grocerymate\\\_db` if it does not exist.
   * Creates or updates user `grocery\\\_user` with password `grocery\\\_test`.
   * Grants full privileges to `grocery\\\_user` on the `public` schema.
7. **Imports seed data**

   * If the `public` schema has zero tables, imports `sqlite\\\_dump\\\_clean.sql` into `grocerymate\\\_db` as `grocery\\\_user`.
   * Skips import if tables already exist (idempotent behavior).
8. **Builds and runs Docker container**

   * Builds image `grocerymate` from the backend directory.
   * Removes any existing container named `grocerymate-app`.
   * Runs container with:

     * Host networking.
     * Restart policy `unless-stopped`.
     * Environment variables:

       * `S3\\\_BUCKET\\\_NAME`, `S3\\\_REGION`, `USE\\\_S3\\\_STORAGE`.
       * `POSTGRES\\\_USER`, `POSTGRES\\\_PASSWORD`, `POSTGRES\\\_DB`, `POSTGRES\\\_HOST`, `POSTGRES\\\_URI`.
9. **Verification**

   * Executes `SELECT COUNT(\\\*) FROM products;` as `grocery\\\_user` and logs the result.

\---

## Terraform Usage

From the `infrastructure/` directory.

### 1\. Prerequisites

* Terraform >= 1.5.
* AWS account and credentials configured (for example, using `aws configure`).
* Existing EC2 key pair name (for SSH) in the target region.

### 2\. Configure `terraform.tfvars`

Example:

```hcl
aws\\\_region        = "eu-central-1"
project\\\_name      = "grocery-app"
ec2\\\_instance\\\_type = "t3.micro"
key\\\_name          = "amer"
my\\\_ip             = "YOUR\\\_PUBLIC\\\_IP/32"
db\\\_password       = "Ronaldo\\\_goat"
```

Replace `YOUR\\\_PUBLIC\\\_IP/32` with your actual IP so you can SSH into the instance.

### 3\. Initialize and apply

```bash
terraform init
terraform plan
terraform apply
```

Terraform will create:

* VPC, subnets, IGW, and route table.
* Security groups for EC2 and RDS.
* S3 bucket, versioning, public access block, and bucket policy.
* IAM role and instance profile for EC2 with S3 access.
* RDS PostgreSQL instance.
* EC2 app server with user data.

At the end, Terraform outputs:

* `ec2\\\_public\\\_ip`
* `ec2\\\_public\\\_dns`
* `rds\\\_endpoint`
* `rds\\\_port`

\---

## Accessing the Application

After `terraform apply` completes and user data finishes, the app is available at:

* `http://<ec2\\\_public\\\_ip>:5000` or
* `http://<ec2\\\_public\\\_dns>:5000`.

SSH into the instance:

```bash
ssh -i /path/to/your-key.pem ec2-user@<ec2\\\_public\\\_dns>
```

Useful commands on the instance:

```bash
sudo tail -n 100 /var/log/user-data.log
sudo tail -n 100 /tmp/user-data.log

docker ps
docker logs grocerymate-app --tail 100
```

\---

## RDS and Data Seeding

* RDS is created in private subnets and is not publicly accessible.
* Traffic to PostgreSQL is allowed only from the EC2 security group.
* On first boot, EC2 user data will:

  * Create `grocerymate\\\_db` (if missing).
  * Create/update `grocery\\\_user` / `grocery\\\_test`.
  * Import `sqlite\\\_dump\\\_clean.sql` into RDS if no tables exist in `public`.

Manual inspection from EC2:

```bash
export PGPASSWORD='grocery\\\_test'

psql -h <rds\\\_endpoint>      -U grocery\\\_user      -d grocerymate\\\_db      -c "\\\\dt"

psql -h <rds\\\_endpoint>      -U grocery\\\_user      -d grocerymate\\\_db      -c "SELECT COUNT(\\\*) FROM products;"
```

\---

## S3 Avatars Bucket

* Bucket name: `grocerymate-avatars-70223957`.
* Default avatar uploaded to `avatars/user\\\_default.png`.
* Versioning enabled; public access blocked.
* Bucket policy allows only the EC2 IAM role to:

  * `s3:ListBucket` on the bucket.
  * `s3:GetObject` / `s3:PutObject` on `avatars/\\\*`.

The application uses this bucket for storing and retrieving user avatar images.

\---

## Destroying the Stack

To destroy all resources managed by Terraform:

```bash
terraform destroy
```

This will also destroy the RDS database and S3 bucket (including stored data) if they are still managed resources. Back up any important data before destroying the stack.

\---

## \## Architecture Diagram

## 

## !\[GroceryMate AWS architecture](architecture.png)

