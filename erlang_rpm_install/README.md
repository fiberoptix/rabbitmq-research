# Custom Erlang 27.2.4 Installation for RHEL 8.10

This directory contains the files needed to install a custom build of Erlang 27.2.4 on a RHEL 8.10 server. The Erlang installation will be located in `/app/layered/erlang` with proper security configuration for RabbitMQ service integration.

## Files Included

- `erlang-pre-install.sh` - Installs required runtime dependencies
- `erlang-install.sh` - Installs the RPM and configures ownership/permissions  
- `erlang-27.2.4-1.el8.x86_64.rpm` - Custom Erlang binary RPM (22MB)
- `README.md` - This file

## Prerequisites

- **Target System**: RHEL 8.10 x86_64
- **User Account**: `tmv_prod_run_rmq1` and group `tmv_prod_run_rmq1_g` must exist
- **Privileges**: `sudo` access required for installation
- **Network**: Access to RHEL repositories for dependency installation

## Installation Process

### Step 1: Transfer Files
Copy all files to your target server:

```bash
# Example: using scp
scp -r erlang_ready_to_test/ user@target-server:/tmp/

# Or copy to any location you prefer
```

### Step 2: Navigate to Directory
```bash
cd /tmp/erlang_ready_to_test  # or wherever you copied the files
```

### Step 3: Run Pre-Installation Script
Install required runtime dependencies:

```bash
# Make script executable
chmod +x erlang-pre-install.sh

# Run pre-installation (requires sudo)
sudo ./erlang-pre-install.sh
```

**What this script does:**
- Installs `openssl-libs`, `zlib`, `ncurses-libs`, `systemd-libs`
- Ensures all Erlang runtime dependencies are available

### Step 4: Run Installation Script
Install the Erlang RPM and configure security:

```bash
# Make script executable  
chmod +x erlang-install.sh

# Run installation (requires sudo)
sudo ./erlang-install.sh
```

**What this script does:**
- Installs the custom Erlang RPM via `dnf`
- Changes ownership to `tmv_prod_run_rmq1:tmv_prod_run_rmq1_g`
- Sets secure permissions (755) instead of default 777
- Ensures all binaries are executable
- Verifies installation and shows final configuration

## Verification

After successful installation, you should see:

```bash
# Erlang should be installed at custom location
ls /app/layered/erlang/bin

# Check version
/app/layered/erlang/bin/erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
# Output: "27"

# Verify ownership (should show tmv_prod_run_rmq1:tmv_prod_run_rmq1_g)
ls -ld /app/layered/erlang

# Test basic functionality
/app/layered/erlang/bin/erl -eval 'io:format("Erlang is working!~n"), halt().' -noshell
```

## Security Configuration

The installation automatically configures:

- **Ownership**: `/app/layered/erlang` owned by `tmv_prod_run_rmq1:tmv_prod_run_rmq1_g`
- **Permissions**: 755 (secure, not world-writable)
- **Service Integration**: Ready for RabbitMQ service use

## Next Steps

This Erlang installation is now ready to support RabbitMQ installation. The RabbitMQ installation scripts will automatically detect and use this custom Erlang at `/app/layered/erlang`.

## Troubleshooting

### Common Issues

1. **Service user doesn't exist**
   ```bash
   # Verify user exists
   id tmv_prod_run_rmq1
   getent group tmv_prod_run_rmq1_g
   ```

2. **Permission denied errors**
   - Ensure you're using `sudo` for both scripts
   - Verify current user has sudo privileges

3. **Dependency errors**
   - Ensure server has access to RHEL repositories
   - Run pre-install script before install script

4. **RPM conflicts**
   - Remove any existing system Erlang: `sudo dnf remove erlang*`
   - Clean DNF cache: `sudo dnf clean all`

### Support Information

- **Erlang Version**: 27.2.4 (OTP 27)
- **Installation Prefix**: `/app/layered/erlang`
- **Architecture**: x86_64
- **Built For**: RHEL 8.10
- **Service Account**: tmv_prod_run_rmq1:tmv_prod_run_rmq1_g

This custom Erlang build is optimized for RabbitMQ and includes only the necessary components for a minimal, secure installation. 