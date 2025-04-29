# Removing an Old Module-Based RabbitMQ Installation

This guide outlines the steps to decommission an existing RabbitMQ installation that was likely set up using environment modules (e.g., Lmod, Tcl Modules). This should be done *before* installing a new version using a different method (like the generic Unix tarball approach detailed in `generic_unix_installation_guide.md` and potentially automated by `tmv_rabbitmq_postinstall.sh`).

The goal is to stop the old service, remove its integration points with the operating system (systemd/init.d, logrotate, etc.), and prevent old environment variables from interfering, while carefully preserving necessary data for the upgrade process.

**Prerequisites:**

*   Root or sudo access is required.
*   Identify how the old RabbitMQ service was managed (systemd or init.d).

**Steps:**

1.  **Stop and Disable the Old RabbitMQ Service:**
    *   **Identify the service name:**
        *   Check systemd: `sudo systemctl list-units | grep -i rabbitmq`
        *   Check init.d: `ls /etc/init.d/ | grep -i rabbitmq`
        *   *Example:* Let's assume the old service name is `rabbitmq-server-old`.
    *   **Stop the service:**
        *   If systemd: `sudo systemctl stop rabbitmq-server-old`
        *   If init.d: `sudo service rabbitmq-server-old stop` or `sudo /etc/init.d/rabbitmq-server-old stop`
    *   **Disable the service (prevent auto-start):**
        *   If systemd: `sudo systemctl disable rabbitmq-server-old`
        *   If init.d: `sudo chkconfig rabbitmq-server-old off` (or equivalent command for your system).

2.  **Locate and Backup Old Data/Logs/Config:**
    *   This is crucial for the upgrade. Find and securely back up the following:
    *   **Mnesia Data Directory:** This contains queues, users, permissions, etc. Look for paths specified in the old service definition (see Step 3) via variables like `MNESIA_BASE`, `RABBITMQ_MNESIA_DIR`, or default locations like `/var/lib/rabbitmq` or a path relative to the module installation directory.
        *Example:* `sudo cp -a /path/to/old/mnesia /backup/location/rabbitmq_old_mnesia`
    *   **Log Directory:** Find where old logs were stored (`LOG_BASE`, `RABBITMQ_LOG_DIR`). Back up if needed.
        *Example:* `sudo cp -a /path/to/old/logs /backup/location/rabbitmq_old_logs`
    *   **Configuration Files:** Locate `rabbitmq.conf` and `rabbitmq-env.conf`. Check `/etc/rabbitmq`, paths defined by `RABBITMQ_CONFIG_FILE` in the old service, or within the module installation directory.
        *Example:* `sudo cp /path/to/old/rabbitmq.conf /backup/location/`

3.  **Inspect the Old Service Definition:**
    *   View the contents of the service file identified in Step 1.
        *   Systemd: `sudo systemctl cat rabbitmq-server-old`
        *   Init.d: `sudo less /etc/init.d/rabbitmq-server-old`
    *   **Take note of:**
        *   Any `module load erlang` or `module load rabbitmq` commands.
        *   Environment variable settings (`Environment=...`, `export VAR=...`) like `PATH`, `ERLANG_HOME`, `RABBITMQ_HOME`, `RABBITMQ_CONFIG_FILE`, `MNESIA_BASE`, `LOG_BASE`.
        *   The `User` and `Group` the service ran as.
        *   Paths to the `ExecStart`/`ExecStop` binaries or script commands.

4.  **Remove Old System Integration Files:**
    *   Delete files possibly created manually alongside the module setup. The new installation method will create replacements.
    *   **Service File:**
        *   Systemd: `sudo rm /etc/systemd/system/rabbitmq-server-old.service` (or `/usr/lib/systemd/system/...`)
        *   Systemd Reload: `sudo systemctl daemon-reload`
        *   Init.d: `sudo rm /etc/init.d/rabbitmq-server-old`
    *   **Logrotate Configuration:**
        *   Check `/etc/logrotate.d/` for old files (e.g., `rabbitmq`, `rabbitmq-server-old`).
        *   Remove them: `sudo rm /etc/logrotate.d/<old_rabbitmq_logrotate_conf>`
    *   **Tmpfiles.d Configuration:**
        *   Check `/etc/tmpfiles.d/` and `/usr/lib/tmpfiles.d/` for old files (e.g., `rabbitmq.conf`).
        *   Remove them: `sudo rm /etc/tmpfiles.d/<old_rabbitmq_tmpfiles_conf>`

5.  **Clean Up Environment Loading (If Applicable):**
    *   The primary goal is to prevent the old module environment from interfering with the new installation, especially when the new service starts.
    *   **Check system-wide profiles:** Look inside `/etc/profile` and files within `/etc/profile.d/` for any lines like `module load rabbitmq` or `module load erlang` that are no longer needed for other applications. Comment out or remove them.
    *   **Check user profiles:** If the old service ran as a specific user (identified in Step 3), check that user's `~/.bashrc`, `~/.profile`, etc., for `module load` commands related to RabbitMQ/Erlang and remove them.
    *   *Note:* Often, just removing the old service file (Step 4) is sufficient if module loading was confined to that service's startup environment. These checks are precautionary.

**What NOT to Remove (During this phase):**

*   **Module Installation Files:** The actual Erlang/RabbitMQ directories managed by the module system (e.g., `/apps/erlang/VERSION`, `/apps/rabbitmq/VERSION`) can be left alone for now. They are inactive without the environment variables being set.
*   **Backed-up Data/Logs/Config:** Keep the backups made in Step 2 safe. You will need the data (Mnesia directory) and potentially the configuration for the RabbitMQ upgrade process itself after the new version is installed.

After completing these steps, the system should be prepared for the new RabbitMQ installation using the generic tarball method, without conflicts from the old module-based setup. 