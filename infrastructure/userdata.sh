#!/bin/bash
set -euxo pipefail

LOG_FILE=/tmp/user-data.log
exec > >(tee -a "$LOG_FILE" /var/log/user-data.log) 2>&1

echo "========== USER DATA START =========="
date

APP_DIR=/home/ec2-user/AWS_grocery
BACKEND_DIR=/home/ec2-user/AWS_grocery/backend
SQL_FILE=/home/ec2-user/AWS_grocery/backend/app/sqlite_dump_clean.sql
APP_DB_NAME=grocerymate_db
APP_DB_USER=grocery_user
APP_DB_PASSWORD=grocery_test
APP_IMAGE=grocerymate
APP_CONTAINER=grocerymate-app

echo "Updating system packages..."
dnf update -y

echo "Installing packages..."
dnf install -y git docker postgresql15 python3.11 python3.11-pip

echo "Starting Docker..."
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

echo "Cloning repository..."
cd /home/ec2-user
if [ ! -d "$APP_DIR" ]; then
  git clone --branch version2 https://github.com/Amerelsabbagh/AWS_grocery.git
else
  cd "$APP_DIR"
  git fetch --all
  git checkout version2
  git pull origin version2
fi

chown -R ec2-user:ec2-user "$APP_DIR"

if [ ! -f "$SQL_FILE" ]; then
  echo "ERROR: SQL file not found at $SQL_FILE"
  exit 1
fi

echo "Waiting for RDS..."
until PGPASSWORD="${RDS_MASTER_PASSWORD}" psql "host=${RDS_ENDPOINT} port=5432 dbname=postgres user=${RDS_MASTER_USER} sslmode=require" -c '\q' >/dev/null 2>&1; do
  echo "RDS not ready yet, sleeping..."
  sleep 10
done

echo "Creating database and role..."
PGPASSWORD="${RDS_MASTER_PASSWORD}" psql "host=${RDS_ENDPOINT} port=5432 dbname=postgres user=${RDS_MASTER_USER} sslmode=require" <<EOF
SELECT 'CREATE DATABASE $APP_DB_NAME'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = '$APP_DB_NAME'
)\gexec

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$APP_DB_USER') THEN
    CREATE USER $APP_DB_USER WITH ENCRYPTED PASSWORD '$APP_DB_PASSWORD';
  ELSE
    ALTER USER $APP_DB_USER WITH ENCRYPTED PASSWORD '$APP_DB_PASSWORD';
  END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME TO $APP_DB_USER;
EOF

echo "Granting schema privileges..."
PGPASSWORD="${RDS_MASTER_PASSWORD}" psql "host=${RDS_ENDPOINT} port=5432 dbname=$APP_DB_NAME user=${RDS_MASTER_USER} sslmode=require" <<EOF
GRANT USAGE, CREATE ON SCHEMA public TO $APP_DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $APP_DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $APP_DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $APP_DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $APP_DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $APP_DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $APP_DB_USER;
EOF

echo "Checking if import is needed..."
TABLE_COUNT=$(PGPASSWORD="$APP_DB_PASSWORD" psql "host=${RDS_ENDPOINT} port=5432 dbname=$APP_DB_NAME user=$APP_DB_USER sslmode=require" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")

echo "TABLE_COUNT=$TABLE_COUNT"

if [ "$TABLE_COUNT" = "0" ]; then
  echo "Importing initial data..."
  PGPASSWORD="$APP_DB_PASSWORD" psql "host=${RDS_ENDPOINT} port=5432 dbname=$APP_DB_NAME user=$APP_DB_USER sslmode=require" -f "$SQL_FILE"
else
  echo "Tables already exist, skipping import."
fi

echo "Building image..."
cd "$BACKEND_DIR"
docker build -t "$APP_IMAGE" .

if docker ps -a --format '{{.Names}}' | grep -Eq "^$APP_CONTAINER$"; then
  docker rm -f "$APP_CONTAINER" || true
fi

echo "Starting container..."
docker run -d \
  --name "$APP_CONTAINER" \
  --network host \
  --restart unless-stopped \
  -e S3_BUCKET_NAME=grocerymate-avatars-70223957 \
  -e S3_REGION=eu-central-1 \
  -e USE_S3_STORAGE=true \
  -e POSTGRES_USER="$APP_DB_USER" \
  -e POSTGRES_PASSWORD="$APP_DB_PASSWORD" \
  -e POSTGRES_DB="$APP_DB_NAME" \
  -e POSTGRES_HOST="${RDS_ENDPOINT}" \
  -e POSTGRES_URI="postgresql://$APP_DB_USER:$APP_DB_PASSWORD@${RDS_ENDPOINT}:5432/$APP_DB_NAME?sslmode=require" \
  -p 5000:5000 \
  "$APP_IMAGE"

echo "Verifying products count..."
PGPASSWORD="$APP_DB_PASSWORD" psql "host=${RDS_ENDPOINT} port=5432 dbname=$APP_DB_NAME user=$APP_DB_USER sslmode=require" -c "SELECT COUNT(*) FROM products;" || true

echo "========== USER DATA FINISHED =========="
date