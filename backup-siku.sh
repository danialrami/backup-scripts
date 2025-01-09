#!/bin/bash

###########################################
# System Backup Script for Arch Linux
# This script creates a comprehensive backup of specified system directories
# and generates detailed system information in markdown format
###########################################

# Configuration Variables
BACKUP_DIR="/mnt/barracuda/system-backup"  # Base directory for backups
MAX_BACKUPS=3                              # Number of backups to retain
USERNAME="$(logname)"                      # Get the actual username who ran sudo
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')     # Create unique timestamp for this backup
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"       # Full path for this backup

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
# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    log_message "ERROR: Please run as root"
    exit 1
fi

# Check if backup drive is mounted
if ! mountpoint -q "/mnt/barracuda"; then
    log_message "ERROR: Backup drive not mounted at /mnt/barracuda"
    exit 1
fi

# Check available space
SPACE_NEEDED=$(df -k / | awk 'NR==2 {print $3}')
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
    uname -a
    echo "\`\`\`"
    
    echo -e "\n## Disk Usage"
    echo "\`\`\`"
    df -h
    echo "\`\`\`"
    
    echo -e "\n## Installed Packages (Pacman)"
    echo "\`\`\`"
    pacman -Qe
    echo "\`\`\`"
    
    if command -v flatpak &> /dev/null; then
        echo -e "\n## Installed Packages (Flatpak)"
        echo "\`\`\`"
        flatpak list
        echo "\`\`\`"
    fi
    
    echo -e "\n## Installed Packages (AUR)"
    echo "\`\`\`"
    pacman -Qm
    echo "\`\`\`"
    
    echo -e "\n## Systemd Services Status"
    echo "\`\`\`"
    systemctl list-units --type=service --state=running
    echo "\`\`\`"
    
    if command -v docker &> /dev/null; then
        echo -e "\n## Docker Images"
        echo "\`\`\`"
        docker images
        echo "\`\`\`"
    fi
} > "$BACKUP_PATH/system-info.md"

# Record start time for duration calculation
START_TIME=$(date +%s)

# Create backup using rsync
log_message "INFO: Starting file backup"
rsync -aAXH --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
    --include="/home/$USERNAME/" \
    --include="/home/$USERNAME/**" \
    --include="/etc/**" \
    --include="/usr/local/**" \
    --include="/var/lib/systemd/**" \
    --include="/var/lib/docker/**" \
    --exclude="**/node_modules/**" \
    --exclude="**/.cache/**" \
    --exclude="**/Cache/**" \
    --exclude="**/.npm/**" \
    --exclude="**/.cargo/**" \
    --exclude="**/.rustup/**" \
    --exclude="**/.local/share/Trash/**" \
    --exclude="**/.mozilla/firefox/*.default*/cache/**" \
    --exclude="**/.config/chromium/Default/Cache/**" \
    --exclude="**/.local/share/Steam/**" \
    --exclude="**/.gradle/**" \
    --exclude="**/.m2/**" \
    --exclude="$BACKUP_DIR/**" \
    / "$BACKUP_PATH/system"

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
    
    # Commented out verification step for large backups
    # # Verify backup integrity
    # log_message "INFO: Verifying backup integrity..."
    # rsync -avn --delete --max-alloc=2048M "$BACKUP_PATH/system/" / | grep '^[^>]' > "$BACKUP_PATH/integrity_check.log"
    # if [ -s "$BACKUP_PATH/integrity_check.log" ]; then
    #     log_message "WARNING: Some files differ from source. Check integrity_check.log for details."
    # else
    #     log_message "INFO: Backup integrity verified successfully"
    # fi
    
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
