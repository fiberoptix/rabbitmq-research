# Custom RabbitMQ 4.1 Installation for RHEL 8.10

This guide covers installing RabbitMQ 4.1.0 using our custom RPM and automated installation scripts for both production and test environments.

## Overview

We provide two installation approaches:
- **Production Environment**: Uses `rabbitmq-prod-install-v3.sh` (assumes service users exist via Kerberos/LDAP/SSSD)
- **Test Environment**: Uses `rabbitmq-test-install.sh` (creates local service users + calls production script)

Both approaches install RabbitMQ to `/app/layered/rabbitmq` and integrate with systemd, logrotate, and system limits.

## Prerequisites

### Required Components
1. **Custom Erlang 27.2.4** installed at `/app/layered/erlang`
2. **Service User/Group**: `tmv_prod_run_rmq1` / `tmv_prod_run_rmq1_g`
   - **Production**: Must exist via Kerberos/LDAP/SSSD
   - **Test**: Will be created automatically by test script
3. **Root/sudo access** for installation

### Package Contents
- `rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm` - Custom RabbitMQ RPM (87MB)
- `rabbitmq-prod-install-v3.sh` - Production installation script (18KB)
- `rabbitmq-test-install.sh` - Test environment script (4KB)
- `rabbitmq-install-guide_v3.md` - This installation guide

## Installation Methods

### Method 1: Production Environment

**Use this for production servers where service users are managed by Kerberos/LDAP/SSSD.**

```bash
# 1. Verify prerequisites
id tmv_prod_run_rmq1
getent group tmv_prod_run_rmq1_g
/app/layered/erlang/bin/erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# 2. Install RPM
sudo dnf install -y ./rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm

# 3. Run production installation script
sudo ./rabbitmq-prod-install-v3.sh
```

### Method 2: Test/Dev Environment

**Use this for test servers where you need to create service users locally.**

```bash
# 1. Verify Erlang prerequisite
/app/layered/erlang/bin/erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# 2. Run test installation (handles RPM install + user creation + production setup)
sudo ./rabbitmq-test-install.sh
```

## What the Installation Scripts Do

### Production Script (rabbitmq-prod-install-v3.sh)

1. **Pre-flight Checks**
   - Verifies Erlang 27.x installation at `/app/layered/erlang`
   - Validates service user/group existence
   - Checks installation directory

2. **System Integration**
   - Creates `/app/layered/rabbitmq/etc/rabbitmq/rabbitmq-env.conf`
   - Sets up SystemD service at `/etc/systemd/system/rabbitmq-server.service` with environment variables
   - Configures logrotate at `/etc/logrotate.d/rabbitmq-server`
   - Sets up tmpfiles.d at `/etc/tmpfiles.d/rabbitmq-server.conf`
   - Configures system limits at `/etc/security/limits.d/99-tmv-rabbitmq.conf`

3. **Permissions & Ownership**
   - Sets ownership of `/app/layered/rabbitmq` to service user
   - Creates home directory if missing (`/home/tmv_prod_run_rmq1`)
   - Configures environment variables in `.bashrc`

4. **SELinux Configuration** (RHEL/CentOS with SELinux enabled)
   - Automatically detects SELinux enforcement status
   - Sets `bin_t` context on RabbitMQ executables for systemd compatibility
   - Makes context changes persistent across reboots
   - Handles missing SELinux tools gracefully

5. **Service Management**
   - Enables rabbitmq-server service for auto-start
   - Creates runtime configuration script for post-start setup

### Test Script (rabbitmq-test-install.sh)

1. **Test-Specific Tasks**
   - Auto-detects package manager (dnf vs yum)
   - Creates system user/group if they don't exist
   - Creates home directory with proper permissions
   - Installs RabbitMQ RPM

2. **Delegates to Production Script**
   - Calls `rabbitmq-prod-install-v3.sh` for all system integration

## Generated Configuration Files

### RabbitMQ Environment (`/app/layered/rabbitmq/etc/rabbitmq/rabbitmq-env.conf`)
```bash
# Base directory of the installation
BASE=/app/layered/rabbitmq

# Data and Log directories
NODENAME=rabbit@hostname
NODE_IP_ADDRESS=127.0.0.1
MNESIA_BASE=$BASE/var/lib/rabbitmq/mnesia
LOG_BASE=$BASE/var/log/rabbitmq

# RabbitMQ Environment Variables
RABBITMQ_HOME=/app/layered/rabbitmq
RABBITMQ_MNESIA_BASE=/app/layered/rabbitmq/var/lib/rabbitmq
RABBITMQ_MNESIA_DIR=/app/layered/rabbitmq/var/lib/rabbitmq/mnesia
RABBITMQ_LOG_BASE=/app/layered/rabbitmq/var/log/rabbitmq

# Erlang Environment Variable
ERLANG_HOME=/app/layered/erlang
```

### SystemD Service (`/etc/systemd/system/rabbitmq-server.service`)
```ini
[Unit]
Description=RabbitMQ Broker Service (TMV Custom Install)
After=network.target epmd@.socket
Wants=network.target epmd@.socket sssd.service

[Service]
Type=notify
User=tmv_prod_run_rmq1
Group=tmv_prod_run_rmq1_g
WorkingDirectory=/app/layered/rabbitmq

# Environment variables for RabbitMQ and Erlang
Environment=ERLANG_HOME=/app/layered/erlang
Environment=RABBITMQ_HOME=/app/layered/rabbitmq
Environment=PATH=/app/layered/rabbitmq/sbin:/app/layered/erlang/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RemainAfterExit=yes
ExecStart=/app/layered/rabbitmq/sbin/rabbitmq-server
ExecStop=/app/layered/rabbitmq/sbin/rabbitmqctl stop_app
NotifyAccess=all
TimeoutStartSec=3600
TimeoutStopSec=3600
Restart=always
RestartSec=10
UMask=0027
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
```

## Post-Installation Steps

### 1. Start RabbitMQ Service
```bash
sudo systemctl start rabbitmq-server
sudo systemctl status rabbitmq-server
```

### 2. Runtime Configuration (Two-Phase Setup)
```bash
# Switch to service user
sudo su - tmv_prod_run_rmq1

# Run runtime configuration script
cd /app/layered/rabbitmq/sbin
./rabbitmq-post-install.sh
```

This runtime script:
- Enables rabbitmq_management plugin
- Creates admin user (admin/admin)
- Sets administrator permissions
- Verifies configuration

### 3. Access Management UI
- **URL**: `http://your-server:15672`
- **Username**: `admin`
- **Password**: `admin`

## Directory Structure

After installation, RabbitMQ will be organized as:
```
/app/layered/rabbitmq/
├── sbin/              # Control scripts
├── escript/           # Erlang executables  
├── plugins/           # RabbitMQ plugins
├── etc/rabbitmq/      # Configuration files
├── var/
│   ├── lib/rabbitmq/mnesia/  # Database storage
│   └── log/rabbitmq/         # Log files
└── share/             # Documentation, man pages
```

## System Integration Files

- `/etc/systemd/system/rabbitmq-server.service` - SystemD service
- `/etc/logrotate.d/rabbitmq-server` - Log rotation
- `/etc/tmpfiles.d/rabbitmq-server.conf` - Runtime directories
- `/etc/security/limits.d/99-tmv-rabbitmq.conf` - System limits (100k file descriptors)

## Management Commands

### Service Account Login Banner

When logging in as the service user, you'll see a helpful banner with commands:

```bash
# Switch to service user
sudo su - tmv_prod_run_rmq1

# You'll see this banner:
==========================================
  RabbitMQ Service Account (tmv_prod_run_rmq1)
==========================================
RabbitMQ Installation: /app/layered/rabbitmq
Erlang Installation:   /app/layered/erlang

Common RabbitMQ Commands:
  rabbitmqctl status      - Check RabbitMQ status
  rabbitmqctl stop_app    - Stop RabbitMQ application
  rabbitmqctl start_app   - Start RabbitMQ application
  rabbitmqctl list_users  - List all users
  rabbitmq-plugins list   - List available plugins

Service Management (requires sudo):
  sudo systemctl status rabbitmq-server
  sudo systemctl start rabbitmq-server
  sudo systemctl stop rabbitmq-server

Management UI: http://localhost:15672 (admin/admin)
Logs: /app/layered/rabbitmq/var/log/rabbitmq/
==========================================
```

### Application Control Commands

The RabbitMQ control binaries are automatically in the service user's PATH:

```bash
# As service user (tmv_prod_run_rmq1)
rabbitmqctl status           # Check application status
rabbitmqctl stop_app         # Stop RabbitMQ application only (not Erlang VM)
rabbitmqctl start_app        # Start RabbitMQ application
rabbitmqctl reset            # Reset RabbitMQ (removes all data!)
rabbitmqctl force_reset      # Force reset when clustering

# Alternative: Use full paths if needed
/app/layered/rabbitmq/sbin/rabbitmqctl status
```

### Service Management
```bash
# Start/stop/restart service (as root/sudo user)
sudo systemctl start rabbitmq-server
sudo systemctl stop rabbitmq-server
sudo systemctl restart rabbitmq-server
sudo systemctl status rabbitmq-server

# Check service logs
sudo journalctl -u rabbitmq-server -f

# Quick status check from any user
sudo su - tmv_prod_run_rmq1 -c 'rabbitmqctl status'
```

### User Management
```bash
# As service user (tmv_prod_run_rmq1)
rabbitmqctl list_users                              # List all users
rabbitmqctl add_user myuser mypassword             # Add new user
rabbitmqctl delete_user myuser                     # Delete user
rabbitmqctl set_user_tags myuser administrator     # Set user tags
rabbitmqctl set_permissions -p / myuser ".*" ".*" ".*"  # Set permissions
rabbitmqctl list_permissions                       # List all permissions
```

### Plugin Management
```bash
# As service user
rabbitmq-plugins list                    # List all available plugins
rabbitmq-plugins list -E                 # List only enabled plugins
rabbitmq-plugins enable rabbitmq_management   # Enable management plugin
rabbitmq-plugins disable rabbitmq_management  # Disable management plugin
```

## Troubleshooting

### Common Issues

1. **Service user doesn't exist**
   - Production: Ensure user exists in Kerberos/LDAP/SSSD
   - Test: Use `rabbitmq-test-install.sh` instead

2. **Home directory missing**
   - Fixed automatically by installation scripts
   - Creates `/home/tmv_prod_run_rmq1` with proper ownership

3. **Erlang not found**
   - Ensure Erlang 27.x is installed at `/app/layered/erlang`
   - Check with: `/app/layered/erlang/bin/erl -version`
   - **Fixed**: Environment variables now set in systemd service file

4. **Permission denied / SELinux blocking execution**
   - **Fixed**: Script automatically configures SELinux contexts
   - Manual fix: `sudo chcon -t bin_t /app/layered/rabbitmq/sbin/*`
   - Check SELinux: `getenforce` and `ls -laZ /app/layered/rabbitmq/sbin/rabbitmq-server`

5. **Runtime configuration script hangs**
   - **Fixed**: Improved user existence check in post-install script
   - Manual verification: `rabbitmqctl list_users` should work without hanging

6. **Permission denied**
   - Verify ownership: `sudo ls -la /app/layered/rabbitmq`
   - Should be owned by `tmv_prod_run_rmq1:tmv_prod_run_rmq1_g`

### Log Locations
- **Service logs**: `journalctl -u rabbitmq-server -f`
- **RabbitMQ logs**: `/app/layered/rabbitmq/var/log/rabbitmq/`
- **Installation logs**: Console output from installation scripts

### System Limits Verification
```bash
# Check process limits (after service start)
sudo systemctl status rabbitmq-server | grep -i "max open files"

# Check user limits
sudo su - tmv_prod_run_rmq1 -c 'ulimit -n'
```

## Security Considerations

1. **Change default admin password** after initial setup
2. **Create specific application users** instead of using admin
3. **Review file permissions** on configuration files
4. **Monitor log files** for security events

## Production vs Test Differences

| Aspect | Production | Test |
|--------|------------|------|
| **User Creation** | Users must exist (Kerberos/LDAP) | Creates users locally |
| **Script Used** | `rabbitmq-prod-install-v3.sh` | `rabbitmq-test-install.sh` |
| **Package Manager** | Assumes dnf | Auto-detects dnf/yum |
| **Home Directory** | Created if missing | Always created |
| **Use Case** | Enterprise deployment | Development/testing |

This installation approach provides a robust, enterprise-ready RabbitMQ deployment with proper system integration and security considerations.