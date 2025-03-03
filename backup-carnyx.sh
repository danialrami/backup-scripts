#!/bin/bash

###########################################
# WIP (borked) System Backup Script for Windows (WSL)
# This script creates a comprehensive backup of specified Windows directories
# and generates detailed system information in markdown format
###########################################

# Configuration Variables
BACKUP_DIR="/mnt/d/backups"  # Base directory for backups on Windows D: drive
MAX_BACKUPS=3                # Number of backups to retain
USERNAME="Owner"             # Your Windows username
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

# Helper Functions
log_message() {
    local MESSAGE="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$MESSAGE"
    if [ -f "$BACKUP_PATH/backup.log" ]; then
        echo "$MESSAGE" >> "$BACKUP_PATH/backup.log"
    fi
}

# Cleanup function for interruptions and errors
cleanup() {
    local MESSAGE="INFO: Script interrupted. Cleaning up..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE"
    rm -rf "$BACKUP_PATH"
    exit 1
}

# Error handling
set -euo pipefail

# Set trap for script interruption
trap cleanup SIGINT SIGTERM ERR

# Prerequisite checks
# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Check available space
SPACE_NEEDED=$(du -s /mnt/c/Users/$USERNAME | awk '{print $1}')
SPACE_AVAILABLE=$(df -k "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$SPACE_AVAILABLE" -lt "$SPACE_NEEDED" ]; then
    log_message "ERROR: Insufficient space on backup drive"
    exit 1
fi

# Create backup directory structure
mkdir -p "$BACKUP_PATH"
touch "$BACKUP_PATH/backup.log"

# Start backup process
log_message "INFO: Starting System Backup"

# Generate system information markdown file
log_message "INFO: Generating system information"
{
    echo "# System Backup Information"
    echo -e "\nBackup created on: $(date '+%Y-%m-%d %H:%M:%S')"
    
    echo -e "\n## System Information"
    echo "\`\`\`"
    systeminfo | iconv -f UTF-16LE -t UTF-8
    echo "\`\`\`"
    
    echo -e "\n## Disk Usage"
    echo "\`\`\`"
    wmic logicaldisk get deviceid, freespace, size
    echo "\`\`\`"
    
    echo -e "\n## Installed Programs"
    echo "\`\`\`"
    wmic product get name,version
    echo "\`\`\`"
    
    echo -e "\n## Windows Services Status"
    echo "\`\`\`"
    wmic service where state="running" get caption,name,state
    echo "\`\`\`"
    
} > "$BACKUP_PATH/system-info.md"

# Record start time for duration calculation
START_TIME=$(date +%s)

# Create backup using rsync
log_message "INFO: Starting file backup"
rsync -avz --info=progress2 \
    --exclude={'*.iso','*.vhd','*.vmdk'} \
    --exclude="**/node_modules/**" \
    --exclude="**/.cache/**" \
    --exclude="**/Cache/**" \
    --exclude="**/.npm/**" \
    --exclude="**/.cargo/**" \
    --exclude="**/.rustup/**" \
    --exclude="**/AppData/Local/Temp/**" \
    --exclude="**/AppData/Local/Microsoft/Windows/INetCache/**" \
    /mnt/c/Users/$USERNAME/ "$BACKUP_PATH/Users/$USERNAME/"

# Process backup results
RSYNC_EXIT_CODE=$?
if [ $RSYNC_EXIT_CODE -eq 0 ]; then
    # Calculate backup duration
    TIME_ELAPSED=$(($(date +%s) - START_TIME))
    HOURS=$((TIME_ELAPSED/3600))
    MINUTES=$(((TIME_ELAPSED%3600)/60))
    SECONDS=$((TIME_ELAPSED%60))
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" 2>/dev/null | tail -n1 | cut -f1 || echo "unknown")
    
    # Log backup completion
    log_message "INFO: Backup Successful"
    log_message "INFO: Backup duration - ${HOURS}h:${MINUTES}m:${SECONDS}s"
    log_message "INFO: Backup size: $BACKUP_SIZE"
    
    # Update system-info.md with backup details
    {
        echo -e "\n## Backup Details"
        echo "- Backup Size: $BACKUP_SIZE"
        echo "- Duration: ${HOURS}h:${MINUTES}m:${SECONDS}s"
        echo "- Location: $BACKUP_PATH"
        echo -e "\nSee backup.log for detailed operation log"
    } >> "$BACKUP_PATH/system-info.md"
    
    # Append logs to system-info.md
    {
        echo -e "\n## Backup Log"
        echo "\`\`\`"
        cat "$BACKUP_PATH/backup.log"
        echo "\`\`\`"
    } >> "$BACKUP_PATH/system-info.md"
else
    log_message "ERROR: Backup Failed with exit code $RSYNC_EXIT_CODE"
    cleanup
fi

# Cleanup old backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -type d ! -name "$(basename "$BACKUP_DIR")" | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    log_message "INFO: Removing oldest backup"
    find "$BACKUP_DIR" -maxdepth 1 -type d ! -name "$(basename "$BACKUP_DIR")" -printf '%T+ %p\n' | \
        sort | head -n 1 | cut -d' ' -f2- | xargs rm -rf
fi

log_message "INFO: Backup Script Completed Successfully"
