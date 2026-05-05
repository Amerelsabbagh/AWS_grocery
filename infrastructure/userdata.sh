#!/bin/bash
set -e

# Update OS
dnf update -y

# Install Git
dnf install -y git

# Install Python 3.11 and pip (optional if only using Docker image)
dnf install -y python3.11 python3.11-pip

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Clone your app repository
cd /home/ec2-user
git clone --branch version2 https://github.com/Amerelsabbagh/AWS_grocery.git
cd /home/ec2-user/AWS_grocery/backend

# Build Docker image
docker build -t grocerymate .

# Run Docker container
docker run -d --network host \
  -e S3_BUCKET_NAME=grocerymate-avatars-70223957 \
  -e S3_REGION=eu-central-1 \
  -e USE_S3_STORAGE=true \
  -e POSTGRES_USER=grocery_user \
  -e POSTGRES_PASSWORD=grocery_test \
  -e POSTGRES_DB=grocerymate_db \
  -e POSTGRES_HOST="${RDS_ENDPOINT}" \
  -e POSTGRES_URI="postgresql://grocery_user:grocery_test@${RDS_ENDPOINT}:5432/grocerymate_db" \
  -p 5000:5000 \
  grocerymate

# Optional: install PostgreSQL client
dnf install -y postgresql15