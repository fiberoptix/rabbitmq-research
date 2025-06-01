#!/bin/bash

# RabbitMQ Test Environment Installation Script
# This script is ONLY for DEV/TEST environments where:
# - Service users need to be created locally (not managed by Kerberos/LDAP)
# - Creates target user/group with proper home directories
# - Installs the custom RabbitMQ RPM
# - Delegates all production setup to the production installation script
#
# For PRODUCTION: Use rabbitmq-prod-install-v3.sh directly (assumes users exist via Kerberos/LDAP)

set -euo pipefail

# --- Configuration ---
TARGET_USER="tmv_prod_run_rmq1"
TARGET_GROUP="tmv_prod_run_rmq1_g"
#RPM_NAME="rabbitmq-server-4.1.0-1.el8.x86_64.rpm"
RPM_NAME="rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm"
MAIN_INSTALL_SCRIPT="./rabbitmq-prod-install-v3.sh"
INSTALL_DIR="/app/layered/rabbitmq" # RabbitMQ installation directory
USER_HOME_DIR="/home/$TARGET_USER"  # Home directory for the service user (for test environment)

# --- Helper Functions ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# --- Pre-flight Checks ---
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must be run as root or using sudo."
    exit 1
fi

if [ ! -f "$RPM_NAME" ]; then
    log_error "RPM file '$RPM_NAME' not found in the current directory."
    exit 1
fi

if [ ! -f "$MAIN_INSTALL_SCRIPT" ]; then
    log_error "Main install script '$MAIN_INSTALL_SCRIPT' not found in the current directory."
    exit 1
fi

# --- Detect Package Manager ---
log_info "Detecting package manager..."
if command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
else
    log_error "Neither dnf nor yum package manager found."
    exit 1
fi
log_info "Using package manager: $PKG_MANAGER"

# --- Create Group if it doesn't exist ---
log_info "Checking for target group '$TARGET_GROUP'..."
if ! getent group "$TARGET_GROUP" &>/dev/null; then
    log_info "Target group '$TARGET_GROUP' does not exist. Creating it..."
    if ! groupadd -r "$TARGET_GROUP"; then # -r for system group
        log_error "Failed to create group '$TARGET_GROUP'."
        exit 1
    fi
    log_info "Target group '$TARGET_GROUP' created successfully."
else
    log_info "Target group '$TARGET_GROUP' already exists."
fi

# --- Create User if it doesn't exist ---
log_info "Checking for target user '$TARGET_USER'..."
if ! id "$TARGET_USER" &>/dev/null; then
    log_info "Target user '$TARGET_USER' does not exist. Creating it..."
    # Create system user with proper home directory
    if ! useradd -r -g "$TARGET_GROUP" -d "$USER_HOME_DIR" -m -s /bin/bash -c "RabbitMQ Service Account" "$TARGET_USER"; then
        log_error "Failed to create user '$TARGET_USER'."
        exit 1
    fi
    log_info "Target user '$TARGET_USER' created successfully with home directory at $USER_HOME_DIR."
else
    log_info "Target user '$TARGET_USER' already exists."
    
    # Verify home directory exists (in case user was created differently)
    if [[ ! -d "$USER_HOME_DIR" ]]; then
        log_info "Home directory $USER_HOME_DIR doesn't exist. Creating it..."
        mkdir -p "$USER_HOME_DIR"
        chown "$TARGET_USER:$TARGET_GROUP" "$USER_HOME_DIR"
        chmod 755 "$USER_HOME_DIR"
        log_info "Home directory created and assigned to $TARGET_USER."
    fi
fi

# --- Install RPM ---
log_info "Installing RabbitMQ RPM: $RPM_NAME..."
$PKG_MANAGER install -y "./$RPM_NAME"
log_info "RabbitMQ RPM installation completed."

# --- Run Main Post-Installation Script ---
log_info "Running main post-installation script: $MAIN_INSTALL_SCRIPT..."
# The main script also defines TARGET_USER and TARGET_GROUP, which is fine.
# It will use its own definitions.
if ! bash "$MAIN_INSTALL_SCRIPT"; then
    log_error "Main post-installation script failed."
    exit 1
fi

log_info "-------------------------------------------------------"
log_info "RabbitMQ Test Environment Installation Complete!"
log_info ""
log_info "TEST ENVIRONMENT SETUP:"
log_info "- Created local service user '$TARGET_USER' for testing"
log_info "- Installed RabbitMQ RPM and configured all system integration"
log_info ""
log_info "PRODUCTION NOTE:"
log_info "- In production, use 'rabbitmq-prod-install-v3.sh' directly"
log_info "- Production assumes service users exist via Kerberos/LDAP/SSSD"
log_info "-------------------------------------------------------"
exit 0 