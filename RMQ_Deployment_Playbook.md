# RabbitMQ Deployment Playbook

## **🎯 OBJECTIVE**
Deploy RabbitMQ 4.1.0 + Erlang 27.2.4 custom RPM system on RHEL 8.10 servers. Supports both fresh installations and migrations from Environment Modules-based systems (3.12.6 + Erlang 26.1).

## **⚠️ PREREQUISITES**
- ✅ vSphere snapshot taken
- ✅ RabbitMQ configuration exported via management GUI
- ✅ All installation files transferred to server:
  - `disable-modules.sh`
  - `erlang-pre-install.sh`
  - `erlang-install.sh` 
  - `erlang-27.2.4-1.el8.x86_64.rpm`
  - `rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm`
  - `rabbitmq-prod-install-v3.sh`
- ✅ Root access confirmed
- ✅ Service user `tmv_prod_run_rmq1` exists

**Note**: Replace `tmv_prod_run_rmq1` and `tmv_prod_run_rmq1_g` with your organization's actual RabbitMQ service account and group names.

---

## **🚀 PHASE 2: UPGRADE EXECUTION**

### **Step 1: Disable Current Modules System**
```bash
sudo ./disable-modules.sh
```
**What this does:**
- Stops current RabbitMQ service gracefully
- Creates timestamped backup directory with restore script
- Removes systemd service file (`/etc/systemd/system/rabbitmq.service`)
- Removes module-based startup scripts (`/layered/localbin/rabbitmq/*`)
- Removes RabbitMQ and Erlang module files (keeps Environment Modules system intact)
- Optionally removes old software installations
- Prepares `/app/layered/` directory structure
- **Result**: Current system disabled, ready for new installation

---

### **Step 2: Install Erlang Runtime Dependencies**
```bash
sudo ./erlang-pre-install.sh
```
**What this does:**
- Installs required runtime libraries: `openssl-libs`, `zlib`, `ncurses-libs`, `systemd-libs`
- Ensures all Erlang dependencies are available before RPM installation
- **Result**: System ready for custom Erlang RPM

---

### **Step 3: Install Custom Erlang 27.2.4**
```bash
sudo ./erlang-install.sh
```
**What this does:**
- Installs custom Erlang RPM to `/app/layered/erlang/`
- Changes ownership to `tmv_prod_run_rmq1:tmv_prod_run_rmq1_g`
- Sets secure permissions (755) instead of default 777
- Ensures all binaries are executable
- Verifies installation and shows version
- **Result**: Erlang 27.2.4 installed and ready for RabbitMQ

---

### **Step 4: Install Custom RabbitMQ RPM**
```bash
sudo dnf install -y ./rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm
```
**What this does:**
- Installs RabbitMQ 4.1.0 binaries to `/app/layered/rabbitmq/`
- Unpacks all RabbitMQ components (server, management plugin, etc.)
- **Note**: This only installs files, does NOT configure system integration yet
- **Result**: RabbitMQ 4.1.0 software installed, ready for configuration

---

### **Step 5: Configure System Integration**
```bash
sudo ./rabbitmq-prod-install-v3.sh
```
**What this does:**
- **Pre-flight checks**: Verifies Erlang 27.x and service user exist
- **Creates configuration**: `rabbitmq-env.conf` with custom paths and environment variables
- **SystemD integration**: Creates `/etc/systemd/system/rabbitmq-server.service` with:
  - Built-in environment variables (`ERLANG_HOME`, `RABBITMQ_HOME`, `PATH`)
  - Service user configuration
  - Auto-restart and limits (100k file descriptors)
- **System integration**: Configures logrotate, tmpfiles.d, system limits
- **SELinux configuration**: Sets proper contexts for RHEL systems
- **Ownership & permissions**: Sets proper ownership for service user
- **Service enablement**: Enables `rabbitmq-server` for auto-start at boot
- **Environment setup**: Configures service user's `.bashrc` with paths and login banner
- **Result**: Complete system integration, ready to start service

---

### **Step 6: Start New RabbitMQ Service**
```bash
sudo systemctl start rabbitmq-server
```
**What this does:**
- Starts RabbitMQ 4.1.0 using new systemd service
- Service runs as `tmv_prod_run_rmq1` user
- Uses Erlang 27.2.4 from `/app/layered/erlang/`
- Loads environment variables from systemd service
- Creates initial database and log files
- **Result**: RabbitMQ 4.1.0 running and accessible

---

### **Step 7: Verify Service Status**
```bash
sudo systemctl status rabbitmq-server
```
**What this does:**
- Shows service status (should be "active (running)")
- Displays recent log entries
- Confirms proper startup without errors
- **Expected**: Green "active (running)" status

---

### **Step 8: Run Post-Installation Configuration**
```bash
sudo su - tmv_prod_run_rmq1
cd /app/layered/rabbitmq/sbin
./rabbitmq-post-install.sh
```
**What this does:**
- **Switches to service user**: Ensures proper permissions for RabbitMQ commands
- **Enables management plugin**: Activates web-based management UI
- **Creates admin user**: Sets up default admin/admin credentials
- **Sets permissions**: Configures admin user with full permissions
- **Verifies configuration**: Lists users to confirm setup
- **Result**: Management UI available at `http://server:15672` (admin/admin)

---

## **✅ VERIFICATION STEPS**

After completing all steps, verify the upgrade:

### **1. Check Service Status**
```bash
sudo systemctl status rabbitmq-server
# Should show "active (running)"
```

### **2. Test Management UI**
- Open browser: `http://your-server:15672`
- Login: `admin` / `admin`
- Should see RabbitMQ 4.1.0 dashboard

### **3. Verify Auto-Start Configuration**
```bash
sudo systemctl is-enabled rabbitmq-server
# Should show "enabled"
```

### **4. Check RabbitMQ Status**
```bash
sudo su - tmv_prod_run_rmq1
rabbitmqctl status
# Should show running node with version 4.1.0
```

---

## **🔄 DATA RESTORATION**

After successful upgrade verification:

1. **Import Configuration**: Use management UI to import previously exported configuration
2. **Verify Users/VHosts**: Confirm all users, virtual hosts, and permissions are restored
3. **Test Functionality**: Verify applications can connect and operate normally

---

## **🚨 ROLLBACK PROCEDURE (if needed)**

If upgrade fails, rollback using the backup:

```bash
# Navigate to backup directory (created by disable-modules.sh)
cd /tmp/rabbitmq_modules_backup_YYYYMMDD_HHMMSS

# Run restore script
sudo ./restore.sh

# Start old service
sudo systemctl start rabbitmq

# Revert vSphere snapshot if needed
```

---

## **📋 SUCCESS CRITERIA**

✅ **Service Running**: `systemctl status rabbitmq-server` shows active  
✅ **Management UI**: Accessible at port 15672 with admin login  
✅ **Version Confirmed**: RabbitMQ 4.1.0 + Erlang 27.2.4  
✅ **Auto-Start Enabled**: Service will start automatically on boot  
✅ **Data Restored**: All users, vhosts, and configurations imported  
✅ **Applications Connected**: Production applications can connect successfully  

---

## **⏱️ ESTIMATED TIMELINE**

- **Step 1-2**: 5 minutes (disable modules + dependencies)
- **Step 3-4**: 10 minutes (install Erlang + RabbitMQ RPMs)  
- **Step 5**: 5 minutes (system configuration)
- **Step 6-8**: 10 minutes (start service + post-config)
- **Verification**: 10 minutes (testing and validation)

**Total Upgrade Time**: ~30-40 minutes

---

## **🎯 FINAL NOTES**

- **No reboot required** during upgrade process
- **Optional reboot** after success to test auto-start
- **Keep backups** until system is fully validated
- **Monitor logs** in `/app/layered/rabbitmq/var/log/rabbitmq/` after upgrade
- **Update firewall rules** if needed for port 15672 (management UI)
