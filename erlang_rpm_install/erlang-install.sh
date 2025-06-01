#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Erlang RPM installation..."

# Install the Erlang RPM without prompting for confirmation
sudo dnf install -y ./erlang-27.2.4-1.el8.x86_64.rpm

echo "Erlang RPM installation finished."
echo "Verifying Erlang version..."

# Check the installed Erlang version
INSTALLED_VERSION=$(/app/layered/erlang/bin/erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)

echo "Installed Erlang OTP Release: $INSTALLED_VERSION"

echo "Configuring ownership and permissions for service account..."

# Change ownership to RabbitMQ service account for security
sudo chown -R tmv_prod_run_rmq1:tmv_prod_run_rmq1_g /app/layered/erlang
echo "Changed ownership to tmv_prod_run_rmq1:tmv_prod_run_rmq1_g"

# Fix permissions (more secure than default 777)
sudo chmod -R 755 /app/layered/erlang
echo "Set permissions to 755 (owner: rwx, group: r-x, other: r-x)"

# Ensure binaries are executable
sudo chmod +x /app/layered/erlang/bin/*
sudo chmod +x /app/layered/erlang/erts-*/bin/*
echo "Ensured all binaries are executable"

echo "Verifying final configuration..."
echo "Ownership: $(ls -ld /app/layered/erlang | awk '{print $3":"$4}')"
echo "Permissions: $(ls -ld /app/layered/erlang | awk '{print $1}')"

echo "Installation Complete"

exit 0 