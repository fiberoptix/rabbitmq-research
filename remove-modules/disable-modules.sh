#!/bin/bash

# =============================================================================
# DISABLE-MODULES.SH - RabbitMQ Environment Modules Removal Script
# =============================================================================
#
# PURPOSE:
# This script safely disables the Environment Modules system for RabbitMQ
# and Erlang on a RHEL 8.10 production server, preparing it for upgrade to
# our custom RPM-based installation system.
#
# BACKGROUND:
# - Current system uses Environment Modules to manage RabbitMQ 3.12.6 + Erlang
# - Target system uses custom RPMs with direct systemd integration
# - Current: /layered/rabbitmq/3.12.6/ → Target: /app/layered/rabbitmq/
# - Current: Module-based startup → Target: Direct systemd service
#
# STRATEGY: DISABLE (not complete removal)
# - Removes only RabbitMQ/Erlang-specific module integration
# - Keeps Environment Modules system intact for potential other uses
# - Minimizes risk by only touching RabbitMQ-related files
# - Allows easy rollback by restoring backed-up files
#
# AUTHOR: AI Assistant + Platform Manager
# DATE: September 2025
# VERSION: 1.0
#
# =============================================================================

# Exit immediately if any command fails
set -euo pipefail

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

# Service name for current RabbitMQ installation
CURRENT_SERVICE_NAME="rabbitmq"

# Current installation paths (from our investigation)
CURRENT_RABBITMQ_PATH="/layered/rabbitmq/3.12.6"
CURRENT_ERLANG_PATH="/layered/erlang/26.1"
CURRENT_STARTUP_SCRIPT="/layered/localbin/rabbitmq/start_rabbitmq"
CURRENT_STOP_SCRIPT="/layered/localbin/rabbitmq/stop_rabbitmq"
CURRENT_SYSTEMD_SERVICE="/etc/systemd/system/rabbitmq.service"

# Module files to remove (only RabbitMQ and Erlang specific)
RABBITMQ_MODULE_DIR="/usr/local/Modules/modulefiles/rabbitmq"
ERLANG_MODULE_DIR="/usr/local/Modules/modulefiles/erlang"

# Backup directory for rollback capability
BACKUP_DIR="/tmp/rabbitmq_modules_backup_$(date +%Y%m%d_%H%M%S)"

# Service user (already correct for target system)
SERVICE_USER="tmv_prod_run_rmq1"

# Target directory for new installation (will be created by new install scripts)
TARGET_BASE_DIR="/app/layered"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# SAFETY CHECKS
# =============================================================================

log_info "Starting RabbitMQ Environment Modules Disable Script"
log_info "=================================================="

# Verify running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    log_error "Reason: Need to modify systemd services, stop services, and modify system files"
    exit 1
fi

# Verify this is RHEL 8.10
if [[ ! -f /etc/redhat-release ]]; then
    log_error "This script is designed for RHEL systems only"
    exit 1
fi

RHEL_VERSION=$(cat /etc/redhat-release)
log_info "Detected system: $RHEL_VERSION"

# Verify RabbitMQ service exists and is running
if ! systemctl list-units --type=service | grep -q "$CURRENT_SERVICE_NAME"; then
    log_error "RabbitMQ service '$CURRENT_SERVICE_NAME' not found"
    log_error "Expected to find systemd service - please verify service name"
    exit 1
fi

# Verify key paths exist
if [[ ! -d "$CURRENT_RABBITMQ_PATH" ]]; then
    log_error "Current RabbitMQ installation not found at: $CURRENT_RABBITMQ_PATH"
    log_error "Please verify the installation path is correct"
    exit 1
fi

if [[ ! -d "$CURRENT_ERLANG_PATH" ]]; then
    log_error "Current Erlang installation not found at: $CURRENT_ERLANG_PATH"
    log_error "Please verify the installation path is correct"
    exit 1
fi

if [[ ! -f "$CURRENT_STARTUP_SCRIPT" ]]; then
    log_error "Current startup script not found at: $CURRENT_STARTUP_SCRIPT"
    log_error "This script is required to understand current module integration"
    exit 1
fi

log_success "All safety checks passed"

# =============================================================================
# CREATE BACKUP DIRECTORY
# =============================================================================

log_info "Creating backup directory for rollback capability"
log_info "Backup location: $BACKUP_DIR"

# Create backup directory
# WHY: Allows complete rollback if something goes wrong
mkdir -p "$BACKUP_DIR"

# Create subdirectories for organized backup
mkdir -p "$BACKUP_DIR/systemd"
mkdir -p "$BACKUP_DIR/scripts"
mkdir -p "$BACKUP_DIR/modules"
mkdir -p "$BACKUP_DIR/logs"

log_success "Backup directory created"

# =============================================================================
# BACKUP CURRENT CONFIGURATION
# =============================================================================

log_info "Backing up current configuration files"

# Backup systemd service file
# WHY: This is the main integration point between systemd and modules
if [[ -f "$CURRENT_SYSTEMD_SERVICE" ]]; then
    log_info "Backing up systemd service: $CURRENT_SYSTEMD_SERVICE"
    cp "$CURRENT_SYSTEMD_SERVICE" "$BACKUP_DIR/systemd/"
else
    log_warn "Systemd service file not found at expected location"
fi

# Backup startup scripts
# WHY: These contain the module load commands we need to eliminate
if [[ -f "$CURRENT_STARTUP_SCRIPT" ]]; then
    log_info "Backing up startup script: $CURRENT_STARTUP_SCRIPT"
    cp "$CURRENT_STARTUP_SCRIPT" "$BACKUP_DIR/scripts/"
else
    log_warn "Startup script not found at expected location"
fi

if [[ -f "$CURRENT_STOP_SCRIPT" ]]; then
    log_info "Backing up stop script: $CURRENT_STOP_SCRIPT"
    cp "$CURRENT_STOP_SCRIPT" "$BACKUP_DIR/scripts/"
else
    log_warn "Stop script not found at expected location"
fi

# Backup module files (entire directories)
# WHY: These define the module behavior - needed for potential rollback
if [[ -d "$RABBITMQ_MODULE_DIR" ]]; then
    log_info "Backing up RabbitMQ module files: $RABBITMQ_MODULE_DIR"
    cp -r "$RABBITMQ_MODULE_DIR" "$BACKUP_DIR/modules/"
else
    log_warn "RabbitMQ module directory not found"
fi

if [[ -d "$ERLANG_MODULE_DIR" ]]; then
    log_info "Backing up Erlang module files: $ERLANG_MODULE_DIR"
    cp -r "$ERLANG_MODULE_DIR" "$BACKUP_DIR/modules/"
else
    log_warn "Erlang module directory not found"
fi

# Create a restore script for easy rollback
# WHY: Makes rollback process simple and reduces chance of human error
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# RabbitMQ Modules Restore Script
# This script restores the backed up configuration

set -e

BACKUP_DIR="$(dirname "$0")"
echo "Restoring from backup: $BACKUP_DIR"

# Restore systemd service
if [[ -f "$BACKUP_DIR/systemd/rabbitmq.service" ]]; then
    cp "$BACKUP_DIR/systemd/rabbitmq.service" /etc/systemd/system/
    echo "Restored systemd service"
fi

# Restore scripts
if [[ -f "$BACKUP_DIR/scripts/start_rabbitmq" ]]; then
    cp "$BACKUP_DIR/scripts/start_rabbitmq" /layered/localbin/rabbitmq/
    chmod +x /layered/localbin/rabbitmq/start_rabbitmq
    echo "Restored startup script"
fi

if [[ -f "$BACKUP_DIR/scripts/stop_rabbitmq" ]]; then
    cp "$BACKUP_DIR/scripts/stop_rabbitmq" /layered/localbin/rabbitmq/
    chmod +x /layered/localbin/rabbitmq/stop_rabbitmq
    echo "Restored stop script"
fi

# Restore module files
if [[ -d "$BACKUP_DIR/modules/rabbitmq" ]]; then
    cp -r "$BACKUP_DIR/modules/rabbitmq" /usr/local/Modules/modulefiles/
    echo "Restored RabbitMQ module files"
fi

if [[ -d "$BACKUP_DIR/modules/erlang" ]]; then
    cp -r "$BACKUP_DIR/modules/erlang" /usr/local/Modules/modulefiles/
    echo "Restored Erlang module files"
fi

# Reload systemd
systemctl daemon-reload
echo "Reloaded systemd daemon"

echo "Restore complete. You can now start the rabbitmq service."
EOF

chmod +x "$BACKUP_DIR/restore.sh"

log_success "Backup completed successfully"
log_info "Rollback script created at: $BACKUP_DIR/restore.sh"

# =============================================================================
# STOP RABBITMQ SERVICE
# =============================================================================

log_info "Stopping current RabbitMQ service"

# Get current service status for logging
SERVICE_STATUS=$(systemctl is-active "$CURRENT_SERVICE_NAME" || echo "inactive")
log_info "Current service status: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    log_info "Stopping RabbitMQ service gracefully"
    
    # Stop the service
    # WHY: Must stop service before modifying its configuration
    systemctl stop "$CURRENT_SERVICE_NAME"
    
    # Wait a moment for graceful shutdown
    # WHY: RabbitMQ needs time to close connections and persist data
    sleep 5
    
    # Verify it stopped
    if systemctl is-active "$CURRENT_SERVICE_NAME" >/dev/null 2>&1; then
        log_warn "Service still running, waiting longer..."
        sleep 10
        
        if systemctl is-active "$CURRENT_SERVICE_NAME" >/dev/null 2>&1; then
            log_error "Failed to stop RabbitMQ service"
            log_error "Please stop it manually before continuing"
            exit 1
        fi
    fi
    
    log_success "RabbitMQ service stopped successfully"
else
    log_info "Service was not running"
fi

# Disable the service from auto-starting
# WHY: Prevents the old system from starting during boot after we modify it
log_info "Disabling RabbitMQ service from auto-start"
systemctl disable "$CURRENT_SERVICE_NAME" || log_warn "Service was not enabled"

# =============================================================================
# REMOVE SYSTEMD SERVICE INTEGRATION
# =============================================================================

log_info "Removing systemd service integration"

# Remove the systemd service file
# WHY: This service file calls the module-based startup script
#      Removing it prevents the old system from being used
if [[ -f "$CURRENT_SYSTEMD_SERVICE" ]]; then
    log_info "Removing systemd service file: $CURRENT_SYSTEMD_SERVICE"
    rm -f "$CURRENT_SYSTEMD_SERVICE"
    
    # Reload systemd to recognize the change
    # WHY: systemd needs to be told that service files have changed
    log_info "Reloading systemd daemon"
    systemctl daemon-reload
    
    log_success "Systemd service removed and daemon reloaded"
else
    log_warn "Systemd service file not found - may have been removed already"
fi

# =============================================================================
# REMOVE MODULE-BASED STARTUP SCRIPTS
# =============================================================================

log_info "Removing module-based startup scripts"

# Remove startup script that loads modules
# WHY: This script contains "module load rabbitmq" commands
#      Removing it eliminates the module dependency
if [[ -f "$CURRENT_STARTUP_SCRIPT" ]]; then
    log_info "Removing startup script: $CURRENT_STARTUP_SCRIPT"
    rm -f "$CURRENT_STARTUP_SCRIPT"
    log_success "Startup script removed"
else
    log_warn "Startup script not found"
fi

# Remove stop script
# WHY: For consistency and cleanup - the new system won't use this
if [[ -f "$CURRENT_STOP_SCRIPT" ]]; then
    log_info "Removing stop script: $CURRENT_STOP_SCRIPT"
    rm -f "$CURRENT_STOP_SCRIPT"
    log_success "Stop script removed"
else
    log_warn "Stop script not found"
fi

# Check if the scripts directory is now empty and remove if so
# WHY: Clean up empty directories for a tidy system
SCRIPTS_DIR="$(dirname "$CURRENT_STARTUP_SCRIPT")"
if [[ -d "$SCRIPTS_DIR" ]] && [[ -z "$(ls -A "$SCRIPTS_DIR")" ]]; then
    log_info "Removing empty scripts directory: $SCRIPTS_DIR"
    rmdir "$SCRIPTS_DIR"
    
    # Check if parent directory is empty too
    PARENT_DIR="$(dirname "$SCRIPTS_DIR")"
    if [[ -d "$PARENT_DIR" ]] && [[ -z "$(ls -A "$PARENT_DIR")" ]]; then
        log_info "Removing empty parent directory: $PARENT_DIR"
        rmdir "$PARENT_DIR" || log_warn "Could not remove parent directory"
    fi
fi

# =============================================================================
# REMOVE MODULE FILES (RABBITMQ AND ERLANG ONLY)
# =============================================================================

log_info "Removing RabbitMQ and Erlang module files"

# Remove RabbitMQ module files
# WHY: These files define how "module load rabbitmq" works
#      Removing them prevents the module system from being used for RabbitMQ
if [[ -d "$RABBITMQ_MODULE_DIR" ]]; then
    log_info "Removing RabbitMQ module directory: $RABBITMQ_MODULE_DIR"
    rm -rf "$RABBITMQ_MODULE_DIR"
    log_success "RabbitMQ module files removed"
else
    log_warn "RabbitMQ module directory not found"
fi

# Remove Erlang module files
# WHY: These files define how "module load erlang" works
#      Since RabbitMQ depends on Erlang modules, we remove these too
if [[ -d "$ERLANG_MODULE_DIR" ]]; then
    log_info "Removing Erlang module directory: $ERLANG_MODULE_DIR"
    rm -rf "$ERLANG_MODULE_DIR"
    log_success "Erlang module files removed"
else
    log_warn "Erlang module directory not found"
fi

# NOTE: We deliberately DO NOT remove the entire Environment Modules system
# WHY: Other applications might be using modules
#      We only remove RabbitMQ and Erlang specific modules
#      This is the "DISABLE" approach vs "REMOVE" approach

# =============================================================================
# OPTIONAL: CLEAN UP OLD SOFTWARE INSTALLATIONS
# =============================================================================

log_info "Checking for old software installations to clean up"

# Ask user if they want to remove old installations
# WHY: The old software won't be used, but removing it is optional
#      User might want to keep it for reference or emergency rollback
read -p "Do you want to remove the old RabbitMQ installation at $CURRENT_RABBITMQ_PATH? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -d "$CURRENT_RABBITMQ_PATH" ]]; then
        log_info "Removing old RabbitMQ installation: $CURRENT_RABBITMQ_PATH"
        rm -rf "$CURRENT_RABBITMQ_PATH"
        log_success "Old RabbitMQ installation removed"
        
        # Check if parent directory is empty
        RABBITMQ_PARENT="$(dirname "$CURRENT_RABBITMQ_PATH")"
        if [[ -d "$RABBITMQ_PARENT" ]] && [[ -z "$(ls -A "$RABBITMQ_PARENT")" ]]; then
            log_info "Removing empty parent directory: $RABBITMQ_PARENT"
            rmdir "$RABBITMQ_PARENT" || log_warn "Could not remove parent directory"
        fi
    else
        log_warn "Old RabbitMQ installation directory not found"
    fi
else
    log_info "Keeping old RabbitMQ installation for reference"
fi

# Remove old Erlang installation
# WHY: We know exactly where the old Erlang is installed (version 26.1)
#      This will be replaced by our custom Erlang 27.2.4 RPM
log_info "Checking old Erlang installation: $CURRENT_ERLANG_PATH"

FOUND_ERLANG=""
if [[ -d "$CURRENT_ERLANG_PATH" ]]; then
    FOUND_ERLANG="$CURRENT_ERLANG_PATH"
    log_info "Found current Erlang 26.1 installation: $CURRENT_ERLANG_PATH"
else
    log_warn "Current Erlang installation not found at expected location"
fi

if [[ -n "$FOUND_ERLANG" ]]; then
    read -p "Do you want to remove the old Erlang installation at $FOUND_ERLANG? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing old Erlang installation: $FOUND_ERLANG"
        rm -rf "$FOUND_ERLANG"
        log_success "Old Erlang installation removed"
        
        # Check if parent directory is empty
        ERLANG_PARENT="$(dirname "$FOUND_ERLANG")"
        if [[ -d "$ERLANG_PARENT" ]] && [[ -z "$(ls -A "$ERLANG_PARENT")" ]]; then
            log_info "Removing empty parent directory: $ERLANG_PARENT"
            rmdir "$ERLANG_PARENT" || log_warn "Could not remove parent directory"
        fi
    else
        log_info "Keeping old Erlang installation for reference"
    fi
else
    log_info "No old Erlang installation found in common locations"
fi

# =============================================================================
# PREPARE FOR NEW INSTALLATION
# =============================================================================

log_info "Preparing system for new RabbitMQ installation"

# Create target directory structure
# WHY: Our new custom RPM installation will use /app/layered/
#      Creating this directory prepares the system for the new installation
if [[ ! -d "$TARGET_BASE_DIR" ]]; then
    log_info "Creating target directory structure: $TARGET_BASE_DIR"
    mkdir -p "$TARGET_BASE_DIR"
    
    # Set appropriate permissions
    # WHY: The service user needs to be able to access this directory
    chown root:root "$TARGET_BASE_DIR"
    chmod 755 "$TARGET_BASE_DIR"
    
    log_success "Target directory created"
else
    log_info "Target directory already exists: $TARGET_BASE_DIR"
fi

# Verify service user exists
# WHY: Our new installation requires this specific service user
#      Better to check now than fail during installation
if id "$SERVICE_USER" >/dev/null 2>&1; then
    log_success "Service user '$SERVICE_USER' exists and is ready"
else
    log_error "Service user '$SERVICE_USER' not found"
    log_error "This user is required for the new RabbitMQ installation"
    log_error "Please ensure the user exists before running the new installation"
fi

# =============================================================================
# VERIFICATION AND CLEANUP
# =============================================================================

log_info "Performing final verification"

# Verify module commands no longer work for RabbitMQ/Erlang
# WHY: Confirms that the module integration has been successfully disabled
log_info "Testing module system status"

# Test if module command is still available (it should be)
# WHY: We only disabled RabbitMQ/Erlang modules, not the entire system
if command -v module >/dev/null 2>&1; then
    log_info "Environment Modules system is still available (as intended)"
    
    # Test if our specific modules are gone
    if module avail 2>&1 | grep -q rabbitmq; then
        log_warn "RabbitMQ module still appears to be available"
    else
        log_success "RabbitMQ module successfully removed from module system"
    fi
    
    if module avail 2>&1 | grep -q erlang; then
        log_warn "Erlang module still appears to be available"
    else
        log_success "Erlang module successfully removed from module system"
    fi
else
    log_warn "Module command not available - this is unexpected"
fi

# Verify systemd service is gone
# WHY: Confirms the old service integration has been removed
if systemctl list-units --type=service | grep -q "$CURRENT_SERVICE_NAME"; then
    log_warn "RabbitMQ service still appears in systemd"
else
    log_success "RabbitMQ service successfully removed from systemd"
fi

# Check for any remaining processes
# WHY: Ensures RabbitMQ is completely stopped
if pgrep -f rabbitmq >/dev/null 2>&1; then
    log_warn "RabbitMQ processes still running:"
    pgrep -fl rabbitmq || true
else
    log_success "No RabbitMQ processes running"
fi

# =============================================================================
# COMPLETION SUMMARY
# =============================================================================

log_success "RabbitMQ Environment Modules disable process completed successfully!"
echo
echo "=============================================================================="
echo "                            COMPLETION SUMMARY"
echo "=============================================================================="
echo
echo "✅ WHAT WAS ACCOMPLISHED:"
echo "   • RabbitMQ service stopped and disabled"
echo "   • Systemd service integration removed"
echo "   • Module-based startup scripts removed"
echo "   • RabbitMQ and Erlang module files removed"
echo "   • System prepared for new custom RPM installation"
echo
echo "✅ WHAT WAS PRESERVED:"
echo "   • Environment Modules system (for other potential uses)"
echo "   • Service user '$SERVICE_USER' (ready for new installation)"
echo "   • Complete backup for rollback capability"
echo
echo "📁 BACKUP LOCATION:"
echo "   $BACKUP_DIR"
echo "   • Use '$BACKUP_DIR/restore.sh' to rollback if needed"
echo
echo "🎯 NEXT STEPS:"
echo "   1. Transfer your custom Erlang and RabbitMQ RPM packages to this server"
echo "   2. Run the Erlang installation scripts:"
echo "      • ./erlang-pre-install.sh"
echo "      • ./erlang-install.sh"
echo "   3. Run the RabbitMQ installation scripts:"
echo "      • dnf install -y ./rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm"
echo "      • ./rabbitmq-prod-install-v3.sh"
echo "   4. Start the new RabbitMQ service:"
echo "      • systemctl start rabbitmq-server"
echo "   5. Run post-installation configuration:"
echo "      • sudo su - $SERVICE_USER"
echo "      • cd /app/layered/rabbitmq/sbin"
echo "      • ./rabbitmq-post-install.sh"
echo
echo "⚠️  IMPORTANT REMINDERS:"
echo "   • Import your RabbitMQ configuration via the management UI"
echo "   • Test thoroughly before declaring success"
echo "   • Keep the backup directory until you're confident in the new system"
echo
echo "=============================================================================="

# Save completion log
echo "$(date '+%Y-%m-%d %H:%M:%S') - RabbitMQ modules disable completed successfully" >> "$BACKUP_DIR/completion.log"

log_success "Script completed. System is ready for new RabbitMQ installation."

exit 0
