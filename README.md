# RabbitMQ Research & Custom Installation

A comprehensive, enterprise-ready installation solution for RabbitMQ 4.1.0 and Erlang 27.2.4 on RHEL 8.10 systems. This project provides custom RPM packages and automated installation scripts designed for secure, production-grade deployments.

## 🎯 Project Overview

This repository contains a complete custom installation framework that:

- **Deploys RabbitMQ to a custom location** (`/app/layered/rabbitmq`) instead of standard system paths
- **Uses a custom Erlang build** (27.2.4) optimized for RabbitMQ performance
- **Provides enterprise security** with dedicated service users and proper permissions
- **Includes automated setup scripts** for both production and test environments
- **Integrates with system services** (systemd, logrotate, SELinux)

## 🏗️ How It Works

The installation process follows a two-stage approach:

### Stage 1: Erlang Installation
1. Install runtime dependencies
2. Deploy custom Erlang 27.2.4 RPM to `/app/layered/erlang`
3. Configure ownership and permissions for service user

### Stage 2: RabbitMQ Installation
1. Install custom RabbitMQ 4.1.0 RPM
2. Configure system integration (systemd, logrotate, limits)
3. Set up security contexts and permissions
4. Enable service auto-start and management UI

## 📁 Repository Structure

```
rabbitmq-research/
├── erlang_rpm_install/           # Erlang 27.2.4 installation components
│   ├── README.md                 # Detailed Erlang installation guide
│   ├── erlang-pre-install.sh     # Dependency installation script
│   ├── erlang-install.sh         # Main Erlang installation script
│   └── erlang-27.2.4-1.el8.x86_64.rpm  # Custom Erlang package (22MB)
│
└── rabbitmq_rpm_install/         # RabbitMQ 4.1.0 installation components
    ├── README.md                 # Comprehensive installation guide
    ├── rabbitmq-prod-install-v3.sh      # Production environment script
    ├── rabbitmq-test-install.sh         # Test/dev environment script
    └── rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm  # Custom RabbitMQ package (86MB)
```

## 🚀 Quick Start

### For Production Environments
```bash
# 1. Install Erlang first
cd erlang_rpm_install/
sudo ./erlang-pre-install.sh
sudo ./erlang-install.sh

# 2. Install RabbitMQ
cd ../rabbitmq_rpm_install/
sudo dnf install -y ./rabbitmq-server-4.1.0-1.el8.noarch-v2.rpm
sudo ./rabbitmq-prod-install-v3.sh
```

### For Test/Development Environments
```bash
# 1. Install Erlang first
cd erlang_rpm_install/
sudo ./erlang-pre-install.sh
sudo ./erlang-install.sh

# 2. Install RabbitMQ (includes user creation)
cd ../rabbitmq_rpm_install/
sudo ./rabbitmq-test-install.sh
```

## 🛡️ Security Features

- **Dedicated Service User**: `tmv_prod_run_rmq1` with group `tmv_prod_run_rmq1_g`
- **Secure Permissions**: 755 instead of default 777 permissions
- **SELinux Integration**: Automatic context configuration for RHEL/CentOS
- **System Limits**: Configured file descriptor limits for high-performance operation
- **Custom Installation Paths**: Isolated from system packages to prevent conflicts

## 🔧 System Requirements

- **Operating System**: RHEL 8.10 x86_64
- **Privileges**: Root/sudo access required
- **Service User**: `tmv_prod_run_rmq1` (created automatically in test environments)
- **Network**: Access to RHEL repositories for dependencies

## 📖 Detailed Documentation

### Erlang Installation
For complete Erlang installation instructions, troubleshooting, and configuration details:
👉 **[Erlang Installation Guide](erlang_rpm_install/README.md)**

### RabbitMQ Installation  
For comprehensive RabbitMQ installation, configuration, and post-installation setup:
👉 **[RabbitMQ Installation Guide](rabbitmq_rpm_install/README.md)**

## 🎯 Key Benefits

- **Enterprise-Ready**: Designed for production environments with proper security and service integration
- **Custom Locations**: Avoids conflicts with system packages by using `/app/layered/` prefix
- **Automated Setup**: Scripts handle complex configuration automatically
- **Dual Environment Support**: Separate workflows for production vs test environments
- **Complete Integration**: SystemD, logrotate, SELinux, and system limits all configured
- **Management UI**: Includes automated setup of RabbitMQ management interface

## 🔍 Verification

After installation, RabbitMQ will be accessible at:
- **Service**: `systemctl status rabbitmq-server`
- **Management UI**: `http://your-server:15672` (admin/admin)
- **Installation Path**: `/app/layered/rabbitmq`
- **Erlang Path**: `/app/layered/erlang`

## 📋 Next Steps

1. Follow the detailed installation guides in the respective directories
2. Complete post-installation configuration as outlined in the RabbitMQ guide
3. Set up monitoring and backup procedures for your environment
4. Configure RabbitMQ clusters if running in a multi-node setup

---

This custom installation framework provides a robust, secure, and maintainable way to deploy RabbitMQ in enterprise environments while maintaining full control over configuration and security policies. 