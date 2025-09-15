# **Current Modules System vs Target Custom RPM System**

## **🔄 COMPLETE SYSTEM COMPARISON**

### **CURRENT STATE: Environment Modules System**

#### **Software Locations:**
```
/layered/rabbitmq/3.12.6/           # RabbitMQ 3.12.6 installation
/layered/erlang/26.1/                # Erlang 26.1 installation
/usr/local/Modules/modulefiles/      # Module definitions
```

#### **Service Integration:**
```bash
# Systemd Service: /etc/systemd/system/rabbitmq.service
User=tmv_prod_run_rmq1
Group=tmv_prod_run_rmq1_g
ExecStart=/layered/localbin/rabbitmq/start_rabbitmq
```

#### **Startup Process:**
```bash
# /layered/localbin/rabbitmq/start_rabbitmq
. /usr/local/Modules/init/bash       # Initialize modules
module load rabbitmq                 # Load RabbitMQ module (auto-loads erlang)
rabbitmq-server -detached           # Start RabbitMQ
```

#### **Module Files:**
```tcl
# /usr/local/Modules/modulefiles/rabbitmq/3.12.6
module load erlang                          # Auto-load dependency
prepend-path PATH /layered/rabbitmq/3.12.6/sbin
setenv RABBITMQ_HOME /layered/rabbitmq/3.12.6
setenv RABBITMQ_LOG_BASE /var/log/rabbitmq
# ... other environment variables
```

#### **Environment Variables (Runtime):**
- Set dynamically by modules when `module load` runs
- PATH includes `/layered/rabbitmq/3.12.6/sbin`
- RABBITMQ_HOME, RABBITMQ_LOG_BASE, etc. set by module

---

### **TARGET STATE: Custom RPM System**

#### **Software Locations:**
```
/app/layered/rabbitmq/               # RabbitMQ 4.1.0 (new location!)
/app/layered/erlang/                 # Erlang 27.2.4 (new location!)
```

#### **Service Integration:**
```bash
# Systemd Service: /etc/systemd/system/rabbitmq-server.service
[Service]
Type=notify
User=tmv_prod_run_rmq1
Group=tmv_prod_run_rmq1_g
WorkingDirectory=/app/layered/rabbitmq

# Environment variables BUILT INTO systemd service
Environment=ERLANG_HOME=/app/layered/erlang
Environment=RABBITMQ_HOME=/app/layered/rabbitmq
Environment=PATH=/app/layered/rabbitmq/sbin:/app/layered/erlang/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ExecStart=/app/layered/rabbitmq/sbin/rabbitmq-server
ExecStop=/app/layered/rabbitmq/sbin/rabbitmqctl stop_app
```

#### **Configuration Files:**
```bash
# /app/layered/rabbitmq/etc/rabbitmq/rabbitmq-env.conf
RABBITMQ_HOME=/app/layered/rabbitmq
RABBITMQ_MNESIA_BASE=/app/layered/rabbitmq/var/lib/rabbitmq
RABBITMQ_LOG_BASE=/app/layered/rabbitmq/var/log/rabbitmq
ERLANG_HOME=/app/layered/erlang
```

#### **Environment Variables (Runtime):**
- Set statically in systemd service file
- Set statically in rabbitmq-env.conf
- No dynamic loading required

---

## **🔄 KEY DIFFERENCES ANALYSIS**

### **1. Software Locations**
| Aspect | Current (Modules) | Target (Custom RPM) |
|--------|------------------|-------------------|
| **RabbitMQ** | `/layered/rabbitmq/3.12.6/` | `/app/layered/rabbitmq/` |
| **Erlang** | `/layered/erlang/26.1/` | `/app/layered/erlang/` |
| **Versions** | RabbitMQ 3.12.6 + Erlang 26.1 | RabbitMQ 4.1.0 + Erlang 27.2.4 |

### **2. Environment Variable Management**
| Aspect | Current (Modules) | Target (Custom RPM) |
|--------|------------------|-------------------|
| **Method** | Dynamic via `module load` | Static in systemd + config files |
| **PATH** | Set by module at runtime | Set in systemd Environment= |
| **RABBITMQ_HOME** | Set by module | Set in systemd + rabbitmq-env.conf |
| **ERLANG_HOME** | Set by module | Set in systemd + rabbitmq-env.conf |

### **3. Startup Process**
| Step | Current (Modules) | Target (Custom RPM) |
|------|------------------|-------------------|
| **1** | systemd starts service | systemd starts service |
| **2** | Calls `/layered/localbin/rabbitmq/start_rabbitmq` | Calls `/app/layered/rabbitmq/sbin/rabbitmq-server` directly |
| **3** | Script sources modules init | systemd sets environment variables |
| **4** | Script runs `module load rabbitmq` | No module loading needed |
| **5** | Module sets environment variables | Environment already set |
| **6** | Script runs `rabbitmq-server -detached` | systemd runs rabbitmq-server directly |

### **4. Service Configuration**
| Aspect | Current (Modules) | Target (Custom RPM) |
|--------|------------------|-------------------|
| **Service Name** | `rabbitmq.service` | `rabbitmq-server.service` |
| **Service Type** | Simple (script-based) | Notify (native) |
| **ExecStart** | Custom script | Direct binary |
| **Environment** | Set by script | Set by systemd |
| **Restart Handling** | Basic | Advanced (RestartSec, etc.) |

---

## **🎯 WHAT THE REMOVE-MODULES SCRIPT NEEDS TO DO**

### **Phase 1: Stop Current System**
```bash
# Stop current RabbitMQ service
systemctl stop rabbitmq.service
systemctl disable rabbitmq.service
```

### **Phase 2: Remove Module-Based Integration**
```bash
# Remove current systemd service
rm /etc/systemd/system/rabbitmq.service

# Remove module-based startup scripts
rm /layered/localbin/rabbitmq/start_rabbitmq
rm /layered/localbin/rabbitmq/stop_rabbitmq

# Remove module files (optional - disable vs remove decision)
rm /usr/local/Modules/modulefiles/rabbitmq/3.12.6
rm /usr/local/Modules/modulefiles/erlang/[version]
```

### **Phase 3: Clean Up Old Software (Optional)**
```bash
# Remove old RabbitMQ installation
rm -rf /layered/rabbitmq/3.12.6/

# Remove old Erlang installation  
rm -rf /layered/erlang/26.1/

# Remove old service scripts directory
rm -rf /layered/localbin/rabbitmq/
```

### **Phase 4: Prepare for New Installation**
```bash
# Create new directory structure
mkdir -p /app/layered/

# The new installation scripts will handle the rest
```

---

## **💡 KEY INSIGHTS**

### **What Changes:**
1. **Software locations** - `/layered/` → `/app/layered/`
2. **Environment management** - Dynamic modules → Static systemd
3. **Service integration** - Script-based → Direct binary
4. **Configuration** - Module files → Config files
5. **Versions** - 3.12.6 → 4.1.0

### **What Stays the Same:**
1. **Service user** - `tmv_prod_run_rmq1` (already correct!)
2. **Basic functionality** - RabbitMQ still works the same
3. **Management UI** - Still accessible
4. **Data format** - Compatible (with export/import)

### **Why This is Actually Simple:**
- **No service user changes needed** - already using `tmv_prod_run_rmq1`
- **Clean separation** - old in `/layered/`, new in `/app/layered/`
- **Our scripts handle everything** - complete automation
- **Proven process** - we've already tested this installation

---

## **🚀 NEXT STEP: REMOVE-MODULES SCRIPT**

Now I understand exactly what needs to happen. The `remove-modules.sh` script needs to:

1. **Clean up the modules-based system** (service, scripts, modules)
2. **Optionally remove old software** (if we want clean slate)
3. **Prepare for our proven installation process** (directories, permissions)

This is actually **simpler than I initially thought** because:
- We're not migrating between similar systems
- We're completely replacing the integration approach
- Our new system is more robust and standard

Ready to create the `remove-modules.sh` script?
