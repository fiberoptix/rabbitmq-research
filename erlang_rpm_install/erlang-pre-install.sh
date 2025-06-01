#!/bin/bash

# Script to install Erlang runtime dependencies on RHEL 8.x
# This script is intended to be run BEFORE installing the custom Erlang RPM.

echo "Installing Erlang runtime dependencies..."

sudo dnf install -y \
    openssl-libs \
    zlib \
    ncurses-libs \
    systemd-libs

if [ $? -eq 0 ]; then
    echo "Erlang runtime dependencies installed successfully."
    echo "You should now be able to install the custom Erlang RPM."
else
    echo "Failed to install Erlang runtime dependencies. Please check the output above for errors."
    exit 1
fi

exit 0 