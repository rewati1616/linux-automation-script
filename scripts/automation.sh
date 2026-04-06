#!/bin/bash

# ========================================================
# Linux Automation Script - Backup + System Monitoring
# Working in Git Bash on Windows
# ========================================================

set -euo pipefail

# Load configuration
CONFIG_FILE="$(dirname "$0")/../config/config.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "✅ Config loaded successfully"
else
    echo "❌ Config file not found!"
    exit 1
fi

# Create directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

LOG_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log_message() {
    echo "$LOG_TIMESTAMP [$1] $2" | tee -a "$LOG_DIR/automation.log"
}

# ====================== BACKUP FUNCTION ======================
perform_backup() {
    log_message "BACKUP" "=== Starting File Backup ==="

    DATE=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_NAME="backup_$DATE.tar.gz"

    log_message "BACKUP" "Creating backup: $BACKUP_NAME"

    # Backing up Documents and Desktop
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
        "/c/Users/Hp/Documents" \
        "/c/Users/Hp/Desktop" 2>/dev/null || true

    if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
        SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null | awk '{print $1}' || echo "Unknown")
        log_message "BACKUP" "✅ Backup successful! Size: $SIZE"

        # Clean old backups
        find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        log_message "BACKUP" "Old backups cleaned"
    else
        log_message "WARNING" "Backup may be empty"
    fi

    log_message "BACKUP" "=== Backup Completed ==="
}

# ====================== MONITORING FUNCTION ======================
perform_monitoring() {
    log_message "MONITOR" "=== System Monitoring Started ==="

    DISK_USAGE=$(df -h /c 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")

    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        log_message "ALERT" "⚠️ Disk usage high: ${DISK_USAGE}%"
    fi

    echo "$LOG_TIMESTAMP | Disk Usage: ${DISK_USAGE}%" >> "$LOG_DIR/monitor.log"
    log_message "MONITOR" "Monitoring completed"
}

# ====================== MAIN PROGRAM ======================
case "${1:-all}" in
    backup)
        perform_backup
        ;;
    monitor)
        perform_monitoring
        ;;
    *)
        perform_backup
        perform_monitoring
        ;;
esac

log_message "INFO" "✅ Automation script finished successfully"
