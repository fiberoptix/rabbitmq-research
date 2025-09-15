# Environment Modules Removal Tools

This directory contains tools and documentation for safely removing Environment Modules-based RabbitMQ installations and transitioning to the custom RPM-based system provided in this repository.

## 🎯 Purpose

Removes Environment Modules integration from existing RabbitMQ installations running:
- **Current**: RabbitMQ 3.12.6 + Erlang 26.1 (modules-based)
- **Target**: RabbitMQ 4.1.0 + Erlang 27.2.4 (custom RPM-based)

## 📁 Files in this Directory

### **Core Tools**
- **`disable-modules.sh`** - Main removal script with safety checks and rollback capability
- **`rmq-upgrade-playbook.md`** - Step-by-step production upgrade guide

### **Documentation**
- **`Modules_Explained.md`** - What Environment Modules are and why they're used
- **`Module_System_Map.md`** - Complete technical mapping of modules system
- **`Current_vs_Target_Comparison.md`** - Side-by-side comparison of old vs new systems

## 🚀 Quick Start

### Prerequisites
1. Take vSphere snapshot or system backup
2. Export RabbitMQ configuration via management GUI
3. Ensure custom Erlang and RabbitMQ RPMs are available

### Basic Usage
```bash
# 1. Disable modules system
sudo ./disable-modules.sh

# 2. Follow upgrade playbook
# See rmq-upgrade-playbook.md for complete step-by-step process

# 3. Install new system using scripts from parent directories:
#    ../erlang_rpm_install/
#    ../rabbitmq_rpm_install/
```

## ⚠️ Production Safety

- **Backup Required**: Always take system snapshot before running
- **Rollback Available**: Script creates timestamped backup with restore capability
- **Conservative Approach**: Only removes RabbitMQ/Erlang modules, preserves Environment Modules system
- **Verification Steps**: Comprehensive checks before and after each operation

## 🔗 Integration with Repository

This modules removal process integrates seamlessly with the custom RPM installation tools in the parent directories:

1. **Assessment**: Use documentation here to understand current system
2. **Removal**: Run `disable-modules.sh` to safely remove modules integration  
3. **Installation**: Use `../erlang_rpm_install/` and `../rabbitmq_rpm_install/` for new system
4. **Guidance**: Follow `rmq-upgrade-playbook.md` for complete process

## 📋 Supported Systems

- **OS**: RHEL 8.10 x86_64
- **Current RabbitMQ**: 3.12.6 with Environment Modules
- **Current Erlang**: 26.1 with Environment Modules
- **Service User**: `tmv_prod_run_rmq1` (must exist)

## 🎯 Expected Outcome

After successful removal and upgrade:
- ✅ Environment Modules integration disabled
- ✅ RabbitMQ 4.1.0 + Erlang 27.2.4 installed
- ✅ Direct systemd service integration
- ✅ Enhanced security and performance
- ✅ Standard RHEL package management

---

**Note**: This is specialized tooling for transitioning FROM Environment Modules TO the custom RPM system. If you're starting fresh, use the installation directories directly.
