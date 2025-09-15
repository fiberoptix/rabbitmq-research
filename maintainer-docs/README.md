# Maintainer Documentation

This directory contains technical documentation for maintaining, rebuilding, and extending the RabbitMQ custom deployment solution.

## 🎯 Purpose

This documentation is designed for:
- **Future maintainers** who need to rebuild RPMs for new versions
- **AI assistants** helping with maintenance tasks
- **Engineers** extending or modifying the build processes
- **Anyone** needing to understand the technical build decisions and processes

## 📁 Files in This Directory

### **Build Process Documentation**
- **`erlang_rpm_build_session_notes.md`** - Complete Erlang RPM build process with troubleshooting
- **`rabbitmq_rpm_build_session_notes.md`** - Complete RabbitMQ RPM packaging process with solutions
- **`build-environment-setup.md`** - Build host requirements and initial setup steps

### **This README**
- Overview of maintainer resources and how to use them effectively

## 🚀 Quick Start for Maintainers

### **For New Version Rebuilds** (e.g., "rebuild for RabbitMQ 15")

1. **Set up build environment**: Follow `build-environment-setup.md`
2. **Reference build processes**: Use the session notes as step-by-step guides
3. **AI Assistant Integration**: Share these docs with AI assistants for guided rebuilds

### **For AI Assistant Collaboration**

When working with AI assistants on maintenance tasks:

```
"I need help rebuilding the RabbitMQ deployment solution for version X.X. 
Please reference the maintainer documentation in /maintainer-docs/ to 
understand our build processes, previous challenges, and solutions."
```

## 🔑 Key Information for AI Assistants

### **Critical Context Files**
- **Build session notes contain**:
  - Exact commands used in successful builds
  - Specific errors encountered and their solutions
  - Spec file modifications and why they were needed
  - Build environment requirements and configurations
  - Troubleshooting steps for common build failures

### **Build Process Overview**
1. **Erlang Build**: Custom RPM compilation from source with RHEL 8.10 compatibility
2. **RabbitMQ Packaging**: Generic Unix tarball wrapped in custom RPM structure
3. **Installation Integration**: Systemd, logrotate, SELinux, and service account setup

### **Target Environment**
- **OS**: RHEL 8.10 x86_64
- **Installation Prefix**: `/app/layered/` (Erlang and RabbitMQ)
- **Service Integration**: Full systemd integration with custom service files
- **Security**: Dedicated service accounts with proper permissions

## 📋 Maintenance Workflows

### **Version Update Process**
1. Review current session notes for process understanding
2. Set up clean build environment per setup documentation
3. Adapt build processes for new version requirements
4. Test installation on clean RHEL 8.10 system
5. Update documentation with any new discoveries or changes

### **Troubleshooting Build Issues**
- **First**: Check session notes for similar errors and solutions
- **Second**: Verify build environment matches documented requirements
- **Third**: Document new issues and solutions in session notes

## 🎯 Success Metrics

A successful maintenance cycle should produce:
- ✅ **Working RPMs** that install cleanly on RHEL 8.10
- ✅ **Updated documentation** reflecting any process changes
- ✅ **Tested deployment** using the main project playbooks
- ✅ **Institutional knowledge preservation** through updated session notes

## 🔗 Integration with Main Project

This maintainer documentation supports the main project structure:
- **Main README** - User-facing project overview and navigation
- **RMQ_Deployment_Playbook** - Operational deployment guide
- **Component READMEs** - User installation instructions
- **This Directory** - Technical build and maintenance processes

## 💡 Best Practices

### **When Rebuilding for New Versions**
- Always start with a clean build environment
- Document any new challenges or solutions encountered
- Test the complete deployment process, not just RPM creation
- Update version numbers in all relevant documentation

### **When Working with AI Assistants**
- Provide complete context by referencing these maintainer docs
- Ask AI assistants to read the session notes before starting work
- Document any new solutions or processes discovered during AI collaboration

---

**This documentation represents institutional knowledge critical to project continuity. Maintain and update it with each maintenance cycle.**
