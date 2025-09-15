# Build Environment Setup

This document outlines the requirements and setup steps for creating a build environment capable of producing the custom Erlang and RabbitMQ RPMs for this project.

## 🎯 Overview

The build environment is used to create custom RPM packages that install to `/app/layered/` and integrate properly with RHEL 8.10 systemd services, security contexts, and service accounts.

## 📋 Build Host Requirements

### **Operating System**
- **Required**: RHEL 8.10 x86_64 (or compatible - CentOS Stream 8, Rocky Linux 8)
- **Why**: Target compatibility and package dependency alignment
- **Resources**: Minimum 4GB RAM, 20GB free disk space

### **Network Access**
- **Required**: Internet access for downloading source packages and dependencies
- **Repositories**: Access to RHEL 8.10 base, appstream, and EPEL repositories

## 🛠️ Required Build Tools

### **Core Build Environment**
```bash
# Install essential build tools
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y rpm-build rpmdevtools rpmlint

# Install EPEL for additional tools
sudo dnf install -y epel-release
```

### **Erlang Build Dependencies**
```bash
# Dependencies for Erlang compilation (from session notes)
sudo dnf install -y \
    openssl-devel \
    ncurses-devel \
    zlib-devel \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    wxGTK3-devel \
    unixODBC-devel \
    java-11-openjdk-devel
```

### **RPM Development Setup**
```bash
# Set up RPM build environment
rpmdev-setuptree

# Verify RPM build directory structure
ls -la ~/rpmbuild/
# Should show: BUILD/ RPMS/ SOURCES/ SPECS/ SRPMS/
```

## 📁 Directory Structure

### **Build Workspace**
```bash
# Create working directories
mkdir -p ~/rabbitmq-build/{erlang,rabbitmq}
cd ~/rabbitmq-build/
```

### **Source Management**
- **Erlang**: Download official OTP source tarball
- **RabbitMQ**: Download generic Unix tarball (not source)
- **Specs**: Custom RPM spec files (documented in session notes)

## 🔧 Build Environment Verification

### **Test RPM Build Capability**
```bash
# Create a test spec file
rpmdev-newspec test
rpmbuild -ba ~/rpmbuild/SPECS/test.spec
```

### **Verify Dependencies**
```bash
# Check essential tools
which rpmbuild gcc make autoconf
rpm -qa | grep -E "(openssl-devel|ncurses-devel|zlib-devel)"
```

## 📝 Pre-Build Checklist

Before starting RPM builds:

- [ ] **Build host** running RHEL 8.10 x86_64
- [ ] **Development Tools** group installed
- [ ] **RPM build environment** configured (`~/rpmbuild/` structure)
- [ ] **Network access** to download sources and dependencies
- [ ] **Sufficient disk space** (20GB+ free)
- [ ] **Session notes** reviewed for specific build processes

## 🎯 Ready to Build

Once this environment is set up, you can proceed with:

1. **Erlang RPM Build**: Follow `erlang_rpm_build_session_notes.md`
2. **RabbitMQ RPM Build**: Follow `rabbitmq_rpm_build_session_notes.md`

## 🔍 Troubleshooting Common Setup Issues

### **Missing Dependencies**
- **Issue**: Build failures due to missing development packages
- **Solution**: Install the complete "Development Tools" group and specific packages listed above

### **RPM Build Directory Issues**
- **Issue**: "cannot create directory" errors during rpmbuild
- **Solution**: Run `rpmdev-setuptree` to create proper directory structure

### **Network/Repository Issues**
- **Issue**: Cannot download sources or dependencies
- **Solution**: Verify RHEL subscription status and repository configuration

---

**This environment setup is the foundation for successful RPM builds. Ensure all requirements are met before proceeding with the build processes documented in the session notes.**
