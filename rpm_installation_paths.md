# RabbitMQ Server RPM Installation Paths

Based on the analysis of the `rabbitmq-server-4.1.0-1.el8.src.rpm` spec file (`rabbitmq-server.spec`), installing the resulting RPM on a RHEL 8+ system will likely install or update files in the following standard directories:

*   `/usr/lib/rabbitmq/lib/rabbitmq_server-4.1.0/`: Core application files, Erlang libraries, and plugins.
*   `/usr/sbin/`: Control scripts (`rabbitmqctl`, `rabbitmq-server`, `rabbitmq-plugins`, `rabbitmq-diagnostics`, `rabbitmq-queues`, `rabbitmq-upgrade`, `rabbitmq-streams`).
*   `/usr/share/man/`: Man pages for RabbitMQ commands.
*   `/usr/share/doc/rabbitmq-server-4.1.0/`: Documentation, license files, examples (e.g., `README`, `LICENSE*`, `set_rabbitmq_policy.sh.example`).
*   `/usr/lib/systemd/system/`: The `rabbitmq-server.service` file for systemd integration.
*   `/etc/logrotate.d/`: The `rabbitmq-server` file for log rotation configuration.
*   `/etc/profile.d/`: The `rabbitmqctl-autocomplete.sh` file for Bash autocompletion setup.
*   `/usr/share/zsh/vendor-functions/`: The `_enable_rabbitmqctl_completion` file for Zsh autocompletion.
*   `/etc/rabbitmq/`: Configuration directory. The spec file primarily ensures this directory exists with correct permissions; main configuration files (`rabbitmq.conf`, `advanced.config`) might be generated on first run or expected to be placed here by the administrator.
*   `/var/lib/rabbitmq/`: Root directory for persistent data.
*   `/var/lib/rabbitmq/mnesia/`: Specific directory for the Mnesia database files (node data, users, permissions, queues, etc.).
*   `/var/log/rabbitmq/`: Directory where log files are stored.
*   `/usr/lib/tmpfiles.d/`: The `rabbitmq-server.conf` file defining runtime directory management.

**Note:**

*   The exact version number (`4.1.0`) in paths might change depending on the built RPM version.
*   Paths like `/etc/rc.d/init.d/` might be included for compatibility with older SysVinit systems but are less relevant for RHEL 8+.
*   The installation scripts (`%pre`, `%post`) also handle creating the `rabbitmq` user and group if they don't exist and manage service state during upgrades. 