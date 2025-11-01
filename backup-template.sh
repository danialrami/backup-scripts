#!/bin/bash

# 1. Configuration Variables
# - Set maximum number of backups to keep
# - Define backup directory path
# - Define UUID of backup drive
MAX_BACKUPS=3
BACKUP_DIR="/hdd/.backup"
BACKUP_UUID="bd25d834-eeb7-45e0-a152-9b226238b9a9"

# 2. Helper Functions
# - Log function for consistent message formatting
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 3. Initial Setup
log_message "INFO: Starting Backup Script"
log_message "INFO: Mounting Backup Drive..."

# 4. Mount Backup Drive
# - Attempt to mount the backup drive using UUID
# - Exit if mounting fails
if ! mount UUID="$BACKUP_UUID" "$BACKUP_DIR"; then
    log_message "ERROR: Backup drive not connected."
    exit 1
fi
log_message "INFO: Successfully Mounted Backup Drive"

# 5. Backup Creation
# - Record start time
# - Create compressed backup using tar and zstd
# - Exclude specified directories
log_message "INFO: Starting Tar Backup"
START_TIME=$(date +%s)

tar -c -I 'zstd -22 --fast=3 -T0' \
    -f "$BACKUP_DIR/backup-$(date -I).tar.xz" \
    # --exclude="/hdd/media/tv" \
    # --exclude="/hdd/media/movies" \
    # --exclude="/hdd/.torrents" \
    # --exclude="$BACKUP_DIR" \
    /hdd

# 6. Check Backup Status and Calculate Duration
# - Check if tar command was successful
# - Calculate and display backup duration
if [ $? -eq 0 ]; then
    TIME_ELAPSED=$(($(date +%s) - START_TIME))
    HOURS=$((TIME_ELAPSED/3600))
    MINUTES=$((TIME_ELAPSED%3600/60))
    SECONDS=$((TIME_ELAPSED%60))
    log_message "INFO: Backup Successful"
    log_message "INFO: Backup duration - ${HOURS}h:${MINUTES}m:${SECONDS}s"
else
    log_message "ERROR: Tar Backup Failed"
    umount "$BACKUP_DIR"
    exit 1
fi

# 7. Backup Rotation
# - Count existing backups
# - Remove oldest backup if exceeding MAX_BACKUPS
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    log_message "INFO: Removing oldest backup"
    ls -1t "$BACKUP_DIR" | tail -n 1 | xargs -d '\n' rm -f
fi

# 8. Final Status
# - List current backups
# - Unmount backup drive
log_message "INFO: Current Backups:"
ls -la "$BACKUP_DIR"

# 9. Cleanup
# - Unmount the backup drive
umount "$BACKUP_DIR"
log_message "INFO: Backup Drive Unmounted"
log_message "INFO: Backup Script Completed Successfully"
