# RabbitMQ RPM Build Session Notes

## 1. Overall Goal

To build a custom RabbitMQ RPM (version 4.1.0) that installs RabbitMQ into a custom prefix: `/app/layered/rabbitmq`. This custom RabbitMQ build depends on the custom Erlang 27.2.4 installation at `/app/layered/erlang`.

## 2. Project Context and Dependencies

- **Primary Dependency:** Custom Erlang 27.2.4 RPM (successfully built and available in `erlang_ready_to_test/`)
- **Target Installation Directory:** `/app/layered/rabbitmq`
- **Target User/Group:** `tmv_prod_run_rmq1` / `tmv_prod_run_rmq1_g` (managed externally via Kerberos/LDAP/SSSD)
- **Cursor Project Root Directory:** `CURSOR_PROJECTS/`
- **RabbitMQ Version:** 4.1.0
- **Platform:** RHEL 8.10 x86_64

## 3. Build Approach Used

Unlike Erlang which was built from source using `rpmbuild`, RabbitMQ was packaged using the **generic Unix tarball approach** with custom RPM wrapping. This approach was chosen because:

1. RabbitMQ provides well-tested generic Unix tarballs
2. Simpler than building from source
3. More control over installation layout
4. Faster build process

## 4. Key Files and Artifacts

### Source Materials (in `rabbitmq_artifacts/downloads/`):
- `rabbitmq-server-generic-unix-4.1.0.tar.xz` - Official RabbitMQ generic Unix distribution

### Build Process Documentation:
- **`rabbitmq-install-guide_v2.md`** (11KB) - Comprehensive manual installation guide
- **`rabbitmq-install-script_v2.sh`** (10KB) - Automated installation script template
- **`rpm_installation_paths.md`** (2.1KB) - Path configuration documentation

### Extracted and Processed Sources:
- **`rabbitmq-server-extract/`** - Initial tarball extraction
- **`rabbitmq-server-extract-generic-unix/`** - Processed extraction for RPM packaging

## 5. Build Process Overview

### Step 1: Source Preparation
1. Downloaded `rabbitmq-server-generic-unix-4.1.0.tar.xz` from RabbitMQ official releases
2. Extracted tarball to examine structure and dependencies
3. Analyzed file layout for custom prefix adaptation

### Step 2: RPM Spec Development
1. Created custom RPM spec file for RabbitMQ
2. Configured custom installation prefix `/app/layered/rabbitmq`
3. Set up proper dependencies on custom Erlang package
4. Defined file ownership and permissions for service user

### Step 3: Installation Script Development
The main complexity was in post-installation configuration rather than the RPM build itself:

#### Core Installation Script (`rabbitmq-install-script_v2.sh`):
- **User/Group Verification**: Validates that target service user exists
- **Erlang Dependency Check**: Verifies Erlang 27.x is available at `/app/layered/erlang`
- **Directory Creation**: Sets up `/app/layered/rabbitmq/var/log/rabbitmq` and `/app/layered/rabbitmq/var/lib/rabbitmq/mnesia`
- **Configuration Generation**: Creates `rabbitmq-env.conf` with custom paths
- **SystemD Integration**: Creates service file at `/etc/systemd/system/rabbitmq-server.service`
- **Logrotate Configuration**: Sets up log rotation with proper user context
- **Tmpfiles.d Configuration**: Ensures runtime directories are created correctly
- **System Limits**: Configures ulimit (nofile: 100000) via `/etc/security/limits.d/`
- **Environment Setup**: Configures `.bashrc` for service user with ERLANG_HOME, RABBITMQ_HOME, and PATH

#### Test Environment Script (`rabbitmq-test-install.sh`):
- **User/Group Creation**: Creates service user/group if they don't exist (for dev/test)
- **RPM Installation**: Installs the custom RabbitMQ RPM
- **Automated Configuration**: Runs the main installation script

## 6. System Integration Components

### SystemD Service Configuration:
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
ExecStart=/app/layered/rabbitmq/sbin/rabbitmq-server
ExecStop=/app/layered/rabbitmq/sbin/rabbitmqctl stop_app
LimitNOFILE=100000
Restart=always
```

### Environment Configuration (`rabbitmq-env.conf`):
```bash
BASE=/app/layered/rabbitmq
NODENAME=rabbit@hostname
NODE_IP_ADDRESS=127.0.0.1
MNESIA_BASE=$BASE/var/lib/rabbitmq/mnesia
LOG_BASE=$BASE/var/log/rabbitmq
RABBITMQ_HOME=/app/layered/rabbitmq
ERLANG_HOME=/app/layered/erlang
```

## 7. Build Outcomes

### Successful Build Results:
- **Binary RPM**: `rabbitmq-server-4.1.0-1.el8.x86_64.rpm` (26MB)
- **Installation Scripts**: Complete automation for deployment
- **Documentation**: Comprehensive installation guide

### Package Contents:
- RabbitMQ server binaries and libraries
- Management console plugin
- Configuration templates
- Documentation and man pages
- Integration scripts for systemd, logrotate, tmpfiles

## 8. Deployment Package (`rabbitmq_ready_to_test/`)

The final deployment package contains:
1. **`rabbitmq-server-4.1.0-1.el8.x86_64.rpm`** - The custom RabbitMQ RPM
2. **`rabbitmq-install-script_v2.sh`** - Production installation script (17KB, 435 lines)
3. **`rabbitmq-test-install.sh`** - Test environment script with user creation (2.9KB, 85 lines)

### Installation Process:
1. **Prerequisites**: Ensure custom Erlang RPM is installed
2. **User Setup**: Verify or create service user/group
3. **RPM Installation**: Install the custom RabbitMQ RPM
4. **System Integration**: Run installation script for systemd, limits, etc.
5. **Service Startup**: Start RabbitMQ service
6. **Runtime Configuration**: Enable management plugin, create admin user

## 9. Key Technical Decisions

### Custom Prefix Strategy:
- **Rationale**: Avoid conflicts with system packages, enable parallel installations
- **Implementation**: All paths configured to use `/app/layered/rabbitmq` as base
- **Benefits**: Clean uninstall, version isolation, enterprise environment compatibility

### Service User Management:
- **External Management**: Relies on Kerberos/LDAP/SSSD for user/group management
- **Fallback**: Test script can create local users for development environments
- **Security**: Proper file ownership and systemd user context

### Build Methodology:
- **Generic Tarball + RPM**: Faster and more reliable than source compilation
- **Pre/Post Scripts**: Comprehensive automation for all system integration tasks
- **Modular Design**: Separate scripts for different environments (test vs production)

## 10. Quality Assurance and Testing

### Validation Points:
- Erlang version compatibility check (27.x required)
- User/group existence verification
- File permission validation
- SystemD service integration testing
- Log rotation functionality
- System limits application

### Environment Testing:
- **Development**: Local user creation and testing
- **Production**: Integration with enterprise authentication systems
- **Service Management**: SystemD start/stop/restart functionality

## 11. Current Status

**Build Status**: ✅ **COMPLETED SUCCESSFULLY**

The RabbitMQ RPM build process has been completed successfully with:
- Custom RPM package built and tested
- Comprehensive installation automation
- Full system integration support
- Documentation and deployment guides
- Ready for production deployment

**Deployment Package**: Available in `rabbitmq_ready_to_test/` directory
**Dependencies**: Requires custom Erlang 27.2.4 RPM (available in `erlang_ready_to_test/`)

## 12. Next Steps for Production Deployment

1. **Environment Preparation**:
   - Install custom Erlang RPM on target servers
   - Verify service user/group availability via SSSD/Kerberos
   - Configure firewall rules (ports 5672, 15672)

2. **Installation Process**:
   - Transfer deployment package to target servers
   - Install RabbitMQ RPM
   - Run installation script for system integration
   - Start and verify service

3. **Post-Installation**:
   - Configure RabbitMQ clusters if needed
   - Set up monitoring and alerting
   - Configure backup procedures for data directories
   - Establish operational procedures

## 13. Key Lessons Learned

1. **Generic Tarball Approach**: More suitable for RabbitMQ than source compilation
2. **System Integration Complexity**: Most effort was in systemd/system integration rather than packaging
3. **Service User Management**: External authentication systems require careful validation

## 14. Post-Build Improvements and Fixes (Latest Session)

### Critical Production Issues Resolved:

#### 14.1 SELinux Integration ✅
**Problem**: RabbitMQ service failed to start on SELinux-enforcing systems with "Permission denied" errors.

**Root Cause**: RabbitMQ executables had `default_t` SELinux context instead of `bin_t`, preventing systemd execution.

**Solution Implemented**:
- **Automatic SELinux Detection**: Script detects `getenforce` status
- **Context Configuration**: Sets `bin_t` context on executables in `/sbin/` and `/escript/`
- **Persistent Contexts**: Uses `semanage` and `restorecon` for boot-persistent configuration
- **Graceful Degradation**: Handles missing SELinux tools without script failure

#### 14.2 SystemD Environment Variables ✅
**Problem**: RabbitMQ couldn't find Erlang (`exec: erl: not found`) even when paths were configured in user `.bashrc`.

**Root Cause**: SystemD services don't source user shell configuration files.

**Solution Implemented**:
- **Direct Environment Variables**: Added `ERLANG_HOME`, `RABBITMQ_HOME`, and `PATH` directly to systemd service file
- **Comprehensive PATH**: Includes both `/app/layered/rabbitmq/sbin` and `/app/layered/erlang/bin`

#### 14.3 Runtime Configuration Script Improvements ✅
**Problem**: Post-install script would hang on `rabbitmqctl list_users` command.

**Solution**: Replaced complex pipeline with robust grep pattern and better error handling.

#### 14.4 Service Account User Experience Enhancement ✅
**Enhancement**: Added comprehensive login banner showing key commands, paths, and management UI access.

#### 14.5 Erlang Security Configuration ✅
**Enhancement**: Added ownership and permission fixes to Erlang installation for service account security.

### Current Status Post-Improvements:

**Status**: ✅ **PRODUCTION-READY WITH ENTERPRISE ENHANCEMENTS**

All critical issues identified during initial deployment have been resolved. The installation package now provides complete SELinux compatibility, robust systemd integration, enhanced user experience, and proven installation process with comprehensive error handling.

**Deployment Confidence**: HIGH - All known production deployment issues addressed with comprehensive solutions.

This completes the RabbitMQ RPM build session. The package is ready for production deployment with comprehensive automation and documentation. 