# Project Overview

This project, "Whonix Initium," is a shell script designed to automate the initial setup and configuration of servers running Debian or Ubuntu. It is particularly useful for home lab environments.

The script performs the following actions:
- Updates the system and upgrades packages.
- Installs a curated list of essential packages for development, monitoring, and containerization (including Docker).
- Hardens SSH by disabling password authentication in favor of key-based authentication.
- Manages user permissions by adding the user to the `docker` group.
- Configures the system's timezone automatically.
- Adds a set of convenient command-line aliases for common tasks.
- Creates a custom Message of the Day (MOTD).

# Building and Running

This project is a single shell script and does not require a build process.

To run the script:

1.  **Download the script:**
    ```shell
    wget https://raw.githubusercontent.com/whonixnetworks/initium/main/setup.sh
    ```

2.  **Make it executable:**
    ```shell
    chmod +x setup.sh
    ```

3.  **Execute the script:**
    ```shell
    ./setup.sh
    ```

The script is interactive and will prompt the user for configuration choices regarding SSH, hostname, and Git profile setup.

**WARNING:** The script disables SSH password authentication. Ensure you have SSH key access to the server to avoid being locked out.

# Development Conventions

- The script is written in `bash` and follows the `set -euo pipefail` convention for robust error handling.
- Functions are used to modularize the different stages of the setup process.
- Colored output is used to improve the readability of the script's execution.
- The script includes a "spinner" function to provide visual feedback for long-running operations.
- To prevent accidental re-execution, the script creates a flag file at `/var/log/setup-complete.flag` upon successful completion.
- The list of packages to be installed is defined in an array variable named `packages` at the beginning of the script, making it easy to customize.
