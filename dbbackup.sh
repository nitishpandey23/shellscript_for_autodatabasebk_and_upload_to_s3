#!/bin/bash

# PostgreSQL database credentials
DB_USER="user"
DB_PASSWORD="password"  # Replace this with your actual database password
DB_HOST="ip_or_host-adrress"
DB_PORT="port_no"

# Backup directory
BACKUP_DIR="/home/ubuntu/database_Backup"

# AWS S3 bucket details
AWS_S3_BUCKET="S3_bucketname"
AWS_S3_BUCKET_PATH="folder/"  # Corrected the path

# Timestamp for backup file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Log file to record backup status
LOG_FILE="/home/ubuntu/database_Backup/backup_log.txt"

# Array of databases to back up
DATABASES=("database") # Replace this with actual database name
# Loop through each database in the array
for DB_NAME in "${DATABASES[@]}"; do
    # Create the backup filename
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.backup.gz"

    # Set the PGPASSWORD environment variable
    export PGPASSWORD="$DB_PASSWORD"

    # Perform the backup using pg_dump with gzip compression
    pg_dump --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" "$DB_NAME" --format=custom -Z 9 --file="$BACKUP_FILE" >> "$LOG_FILE" 2>&1

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Backup of $DB_NAME successful. File saved as: $BACKUP_FILE" >> "$LOG_FILE"
    else
        echo "Backup of $DB_NAME failed!" >> "$LOG_FILE"
        continue  # Move on to the next database without uploading the failed backup
    fi

    # Upload the backup file to AWS S3
    aws s3 mv "$BACKUP_FILE" "s3://$AWS_S3_BUCKET/$AWS_S3_BUCKET_PATH" >> "$LOG_FILE" 2>&1

    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "Upload of $DB_NAME backup to S3 successful." >> "$LOG_FILE"
    else
        echo "Upload of $DB_NAME backup to S3 failed!" >> "$LOG_FILE"
    fi
done
