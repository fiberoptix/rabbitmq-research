# Installing RabbitMQ Generic Unix Tarball in a Custom Location (e.g., /app/layered)

The generic Unix tarball for RabbitMQ (`rabbitmq-server-generic-unix-*.tar.xz`) is designed to be self-contained but requires manual system integration if you want it managed like a standard service. Here's how to install it under `/app/layered/rabbitmq` on a RHEL-like system:

# Explanation of this Guide and the associated postinstall script

This document outlines the manual steps required to install and configure RabbitMQ from the generic Unix tarball into a custom location (`/app/layered/rabbitmq`), integrating it with systemd and other system components while running under a specific user (`tmv_prod_rmq`).

Many of the manual configuration steps described in Sections 3 through 6 (creating configuration files, setting permissions, configuring systemd, logrotate, tmpfiles, and system limits) can be automated by using the companion script `tmv_rabbitmq_postinstall.sh` located in the same directory as this guide.

**If using the script:**

1.  Manually perform **Step 1: Unpack the Tarball** below.
2.  Ensure all prerequisites are met (Erlang installed, target user/group exist).
3.  Run the `tmv_rabbitmq_postinstall.sh` script (using `sudo`).
4.  Perform necessary post-script actions (firewall, first start, check logs, manage default user).

**If *not* using the script:** Follow all steps in this guide sequentially.

This guide provides the detailed breakdown of *what* the script does and serves as a reference for manual installation or troubleshooting.

---


**1. Unpack the Tarball:**

```bash
# Example path
INSTALL_DIR="/app/layered/rabbitmq"
mkdir -p "$INSTALL_DIR"
# Assuming the tarball extracts to a versioned directory first
tar -xf rabbitmq-server-generic-unix-<version>.tar.xz -C /app/layered/
# Rename the extracted folder to the desired name
mv /app/layered/rabbitmq-server-<version> "$INSTALL_DIR"
```

**2. Files/Directories Staying within `/app/layered/rabbitmq/`:**

*   **`sbin/`**: Main control scripts.
*   **`lib/`** (Implicit): Core Erlang code.
*   **`plugins/`**: Core plugins.
*   **`escript/`**: Escripts.
*   **`etc/`**: Base configuration directory.
*   **`share/`**: Documentation, man pages, etc.
*   **`var/log/rabbitmq/`** (You create this): Log storage.
*   **`var/lib/rabbitmq/mnesia/`** (You create this): Data/database storage.

**3. Configure RabbitMQ Environment:**

Create or edit `/app/layered/rabbitmq/etc/rabbitmq/rabbitmq-env.conf`. Define where RabbitMQ should find its data and log files *within* your custom structure:

```bash
# /app/layered/rabbitmq/etc/rabbitmq/rabbitmq-env.conf

# Base directory of the installation
BASE=/app/layered/rabbitmq

# Data and Log directories (create these manually first!)
NODENAME=rabbit@${HOSTNAME}
NODE_IP_ADDRESS=127.0.0.1
MNESIA_BASE=$BASE/var/lib/rabbitmq/mnesia
LOG_BASE=$BASE/var/log/rabbitmq

# Optional: Define config file location if not default
# CONFIG_FILE=$BASE/etc/rabbitmq/rabbitmq.conf
```

Make sure to create the specified directories:
```bash
mkdir -p "$INSTALL_DIR/var/log/rabbitmq"
mkdir -p "$INSTALL_DIR/var/lib/rabbitmq/mnesia"
```

**4. System Integration (Requires Root/Sudo):**

These steps integrate the custom installation with the OS:

*   **Verify Target User/Group Exist:**
    *   Ensure the target user (`tmv_prod_rmq`) and group (`tmv_prod_rmqg`), managed externally (e.g., via Kerberos/LDAP/SSSD), are resolvable on the system.
    *   Use commands like `id tmv_prod_rmq` and `getent group tmv_prod_rmqg` to verify.

*   **Set Permissions:**
    ```bash
    # Define target user/group and install dir if not already set
    TARGET_USER="tmv_prod_rmq"
    TARGET_GROUP="tmv_prod_rmqg"
    INSTALL_DIR="/app/layered/rabbitmq"

    chown -R "$TARGET_USER:$TARGET_GROUP" "$INSTALL_DIR"
    # Adjust permissions as needed, e.g.:
    # chmod 755 "$INSTALL_DIR/sbin/"*
    # chmod 700 "$INSTALL_DIR/var/lib/rabbitmq/mnesia"
    # chmod 700 "$INSTALL_DIR/var/log/rabbitmq"
    # etc.
    ```

*   **Systemd Service File:**
    *   Create or copy a template (e.g., from RPM source `rabbitmq-server.service` or the example provided by the postinstall script).
    *   Place it in `/etc/systemd/system/rabbitmq-server.service`.
    *   **Ensure it contains the correct settings:**
        *   `User=tmv_prod_rmq`
        *   `Group=tmv_prod_rmqg`
        *   `WorkingDirectory=$INSTALL_DIR` (e.g., `/app/layered/rabbitmq`)
        *   `ExecStart=$INSTALL_DIR/sbin/rabbitmq-server`
        *   `ExecStop=$INSTALL_DIR/sbin/rabbitmqctl stop` (or `shutdown`)
        *   `LimitNOFILE=100000` (or desired value, matching limits.d setting)
        *   Other necessary directives (Type, Restart, UMask, etc.).
    *   Enable service for boot: `systemctl enable rabbitmq-server`.
    *   *(Starting the service is typically done after verifying all config).*
    *   Verify status later using `systemctl status rabbitmq-server` or `$INSTALL_DIR/sbin/rabbitmq-diagnostics status`.

*   **Logrotate Configuration:**
    *   Create or copy a template (e.g., from RPM source `rabbitmq-server.logrotate` or the example provided by the postinstall script).
    *   Place it in `/etc/logrotate.d/rabbitmq-server`.
    *   **Edit it:** Change the log file path to `$INSTALL_DIR/var/log/rabbitmq/*.log`. Ensure the `postrotate` script (if using `rabbitmqctl rotate_logs`) runs as the correct user (`tmv_prod_rmq`).

*   **Tmpfiles.d Configuration (RHEL 8+):**
    *   Create or copy a template (e.g., from RPM source `rabbitmq-server.tmpfiles` or the example provided by the postinstall script).
    *   Place it in `/etc/tmpfiles.d/rabbitmq-server.conf`.
    *   **Edit it:** Ensure the runtime directory (e.g., `/run/rabbitmq`) is created with the correct user (`tmv_prod_rmq`) and group (`tmv_prod_rmqg`).

*   **Symlinks (Optional):** For convenience, link `sbin` scripts to `/usr/local/sbin`:
    ```bash
    ln -s "$INSTALL_DIR/sbin/rabbitmqctl" /usr/local/sbin/rabbitmqctl
    # ... other scripts ...
    ```

**5. Important Runtime Considerations:**

*   **System Limits (`ulimit`):**
    *   RabbitMQ can use a large number of file descriptors. Production environments often require adjusting system limits.
    *   Check the current limit for the target user with `sudo su - tmv_prod_rmq -s /bin/bash -c 'ulimit -n'`.
    *   It's recommended to allow at least **100000** file descriptors (as configured by the postinstall script and systemd unit). This usually involves creating a file like `/etc/security/limits.d/99-tmv-rabbitmq.conf`:
        ```
        # Limits for RabbitMQ user (tmv_prod_rmq)
        tmv_prod_rmq          soft    nofile  100000
        tmv_prod_rmq          hard    nofile  100000
        ```
    *   Also, ensure the kernel limit `fs.file-max` is higher than the user limit (check with `sysctl fs.file-max`).
    *   You can verify the limit available to the running RabbitMQ process using `$INSTALL_DIR/sbin/rabbitmq-diagnostics status`.

*   **Default User Access:**
    *   RabbitMQ creates a default user `guest` with the password `guest`.
    *   **Security Warning:** By default, this user can **only connect from `localhost`**.
    *   For connections from other machines or for production use, you should:
        *   Create specific users with appropriate permissions using `rabbitmqctl add_user <username> <password>`, `rabbitmqctl set_permissions ...`, etc.
        *   Either delete the `guest` user (`rabbitmqctl delete_user guest`) or change its password and restrict its access.

**6. Managing the Server with rabbitmqctl (Alternative to systemd)**

While integrating with `systemd` (as described in Section 4) is recommended for automatic startup and standard service management, you can also directly interact with the RabbitMQ node using the control script provided in the installation directory.

This is useful for scripting, troubleshooting, or environments where `systemd` is not used or desired for managing RabbitMQ directly.

*   **Location:** The control script is located at `$INSTALL_DIR/sbin/rabbitmqctl` (e.g., `/app/layered/rabbitmq/sbin/rabbitmqctl`).

*   **Common Commands:**
    *   **Stop the Node:** To gracefully shut down the entire RabbitMQ node (including the Erlang VM):
        ```bash
        sudo $INSTALL_DIR/sbin/rabbitmqctl shutdown
        ```
        Alternatively, `stop` stops the RabbitMQ application but leaves the Erlang VM running (matches the systemd `ExecStop` configured earlier):
        ```bash
        sudo $INSTALL_DIR/sbin/rabbitmqctl stop
        ```

    *   **Check Status:** To check if the RabbitMQ application is running on the node and see basic information (similar to `systemctl status` but more RabbitMQ-focused):
        ```bash
        sudo $INSTALL_DIR/sbin/rabbitmqctl status
        ```
        You can also use the `rabbitmq-diagnostics` tool for more detailed status, including file descriptors, memory, etc.:
        ```bash
        sudo $INSTALL_DIR/sbin/rabbitmq-diagnostics status
        ```

    *   **Starting the Node:** `rabbitmqctl` does **not** start the server process itself. Starting is done using the `rabbitmq-server` script (e.g., `$INSTALL_DIR/sbin/rabbitmq-server -detached`). `rabbitmqctl` is used to manage the node *after* it has been started.

    *   **Restarting the RabbitMQ Application:** There isn't a direct equivalent to `systemctl restart`. You would typically stop the node completely and then restart it using the `rabbitmq-server` script. However, `rabbitmqctl stop_app` followed by `rabbitmqctl start_app` can restart the RabbitMQ application *within* the already running Erlang VM, which is faster but doesn't re-initialize the VM.

*   **Permissions:** Commands modifying the node state (like `stop`, `shutdown`) usually need to be run as the user the RabbitMQ server is running as (`tmv_prod_rmq` via `sudo su - tmv_prod_rmq -c '...'`) or as root (`sudo`). Status commands might work as other users depending on configuration.

**Summary:**

The core application runs from `/app/layered/rabbitmq`, requiring manual creation/editing of configuration files (`rabbitmq-env.conf`), systemd units, logrotate, and tmpfiles configurations, pointing back to the custom installation directory. Ensure the target runtime user (`tmv_prod_rmq`) and group exist and grant careful permissions. The `rabbitmq-env.conf` file directs the server to use data/log locations within the custom directory. Pay close attention to system limits (`ulimit`) and default user security for production deployments. Management can be done via `systemctl` (if integrated) or directly using the `rabbitmqctl` tool. 