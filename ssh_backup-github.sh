#!/bin/bash

# Variables
USER=""                      # SSH server username (e.g., root, admin)
SERVER=""                  # SSH server IP or domain (e.g., 192.168.1.100 or example.com)
BACKUP_DIR=""            # Directory to backup SSH Server Directory (e.g., /home/user/documents)
BACKUP_DEST=""          # Local destination for backup on the client system (e.g., /path/to/local/backup) 
TEMP_BACKUP=""    # Temporary backup file name (e.g., temp_backup.tar.gz)
ENCRYPTED_BACKUP="" # Encrypted backup file name (e.g., backup.tar.gz.gpg)
PRIVATE_KEY=""    # Path to your private SSH key (e.g., /path/to/private/key)
GPG_PASSPHRASE=""  # GPG passphrase for encryption (replace with your actual passphrase)

# Date for backup file naming
DATE=$(date +'%Y%m%d_%H%M%S')

# Step 1: Create and Encrypt the Backup (on the server)
echo "Creating and encrypting backup on remote server..."
ssh -i $PRIVATE_KEY $USER@$SERVER "tar -czf /tmp/$TEMP_BACKUP -C $BACKUP_DIR . && \
                  GPG_TTY=$(tty) gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o /tmp/$ENCRYPTED_BACKUP /tmp/$TEMP_BACKUP" <<< "$GPG_PASSPHRASE"

# Step 2: Check if the encrypted backup file exists and then transfer to client system
if ssh -i $PRIVATE_KEY $USER@$SERVER "[ -f /tmp/$ENCRYPTED_BACKUP ]"; then
    echo "Transferring encrypted backup to client system..."
    scp -i $PRIVATE_KEY $USER@$SERVER:/tmp/$ENCRYPTED_BACKUP $BACKUP_DEST/backup_$DATE.tar.gz.gpg
else
    echo "Encryption failed, skipping transfer."
    exit 1
fi

# Step 3: Clean up remote server (remove temporary backup files)
echo "Cleaning up temporary files on the server..."
ssh -i $PRIVATE_KEY $USER@$SERVER "rm -f /tmp/$TEMP_BACKUP /tmp/$ENCRYPTED_BACKUP"

echo "Backup process completed successfully!"
