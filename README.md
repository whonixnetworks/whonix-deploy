# Whonix Initium

<p align="center">
  <img src="/whonix-deploy.png" alt="Backupscripts Logo" width="200"/>
</p>  

#### <center> **Initium**</center>  
<center> *~ the beginning*</center>

A bash script to automate the initial setup of Debian/Ubuntu servers for home lab environments.  

## What It Does

This script performs a comprehensive initial setup for new servers:

- **System Updates** - Updates package lists and upgrades existing packages
- **Essential Packages** - Installs useful tools like Docker, monitoring utilities, and development packages
- **SSH Hardening** - Configures SSH for key-based authentication only (much more secure than passwords)
- **User Management** - Adds your user to the Docker group
- **Time Configuration** - Automatically sets your timezone
- **Custom Aliases** - Adds handy Docker and system management shortcuts to your shell
- **MOTD** - Creates a nice welcome message with your hostname

> [!WARNING]
> This script disables SSH password authentication. Make sure you have your SSH keys ready or are prepared to generate new ones during setup. If you lose your SSH key access, you could get locked out of your server.

## Quick Start

1. Download the script:  
```shell
wget https://raw.githubusercontent.com/whonixnetworks/whonix-deploy/main/setup.sh && chmod +x setup.sh
```

2. Run it:
```shell
./setup.sh
```

3. Follow the prompts - the script will ask you about SSH configuration and guide you through the process.

## What Gets Installed

### Core Packages

- **Docker & Docker Compose** - Container platform
- **System Tools** - htop, btop, iotop, iftop (system monitoring)
- **Network Utilities** - wget, curl, rsync
- **Development** - git, python3, pip
- **Miscellaneous** - tmux, neofetch, midnight commander, figlet

### SSH Configuration

The script will:

- Generate new SSH keys or import your existing ones
- Disable password authentication
- Disable root login with passwords
- Configure secure SSH settings

### Handy Aliases Added

- `dcu` - Docker compose up
- `dcd` - Docker compose down
- `dcl` - Docker compose logs
- `dps` - Docker ps with clean formatting
- And several more for managing docker-compose files

## Requirements

- Debian or Ubuntu server (tested on Ubuntu 22.04 LTS and Debian 12)
- Sudo privileges
- Internet connection

## How It Works

The script runs in several stages:

1. **Asks all questions upfront** - No interruptions once the installation starts
2. **Configures system settings** - Users, groups, timezone, aliases
3. **Sets up SSH security** - Your choice of key import or generation
4. **Installs packages** - All the software you need
5. **Creates MOTD** - Pretty hostname display
6. **Optionally reboots** - To ensure all changes take effect

## After Setup

Once the script completes:

- You'll need to use SSH keys to connect to your server
- Docker commands will work without sudo for your user
- Your custom aliases will be available in new shell sessions
- The system will be updated with security patches

## Safety Features

- **Completion flag** - Prevents accidentally running the script twice
- **SSH config backup** - Creates a backup before modifying SSH settings
- **Clear warnings** - Makes the security implications obvious
- **Error handling** - Stops on critical errors to prevent partial configurations

## Customization

Want to tweak what gets installed? Edit the packages array near the top of the script to add or remove packages.

## Troubleshooting

**Script says it already ran**: Delete `/var/log/setup-complete.flag` to run again.

**Can't SSH after setup**: Make sure you saved your private key during setup and are using it to connect.

**Docker commands need sudo**: Log out and back in after running the script, or restart your SSH session.

> [!NOTE]
> Always test in a non-production environment first.

## Contributing

Found a bug or want to add something? Feel free to open an issue or submit a pull request.

## License

This script is provided as-is. Use at your own risk.






















































































































































































