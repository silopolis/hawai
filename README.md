# Welcome to H.A.W.A.I. 🌴

An **H**ighly **A**vailable **W**eb **A**pplication **I**nfrastructure project.

Started as a DevOps bootcamp exercise, this repository aims to aggregated knowledge and bests practices in designing, building and operating an highly available architecture for web application hosting.


## Compute

In this first implementation it uses the great Vagrant to manage Docker containers.


## Provisioning

Provisioning is done using good old Shell scripts but should evolve towards funkier tools and techniques like proper configuration management and/or immutable containers.


## Environment and configuration

To begin with, everything is configured with simple so called 'env' files:

- the `.env` file for "public" parameters
- the `.env.priv` for secrets
  - included in `.gitignore` for privacy and security
  - `.env.priv.sample` provided for user to rename and fill-in with its
    own secrets.

These being sourced/imported by both Ruby (Vagrantfile) and Bash code, content is strictly limited to bare variables/parameters declaration.

This must evolve toward something prettier and more powerful in that multilang context. Main candidate is YAML (surprise!), but jsonnet has dynamic features that may provide just enough declarative smartness to avoid repeating configuration parsing on all sides...

Configuration files are Jinja templates transformed using the handy `j2cli` tool.


## Networks


### Zoning

- [x] **Admin**
- [x] **Storage**
- [x] **Databases**
- [x] **Applications**
- [x] **Front**
- [ ] **DMZ**


### L2

Layer 2 (bridge) private network for each zone.


### L3

- Hosts have the same IP address (host part) on all networks
- Admin networks have a subnet large enough to accept all hosts
- Hosts IP ranges are "stacked", south to north: Admin > Storage > Databases > Applications > Front \[> DMZ\]


### L4

- [x] Front TLS termination for user traffic
- [ ] Encrypt all sensitive internal flows
  - [ ] Logs
  - [ ] Backups
- [ ] On all hosts, only accept connection to the configured services from hosts on the relevant networks
- [ ] TCPwrapper allow/deny ?


## Services

- **admin**: bastion host(s)
  - [ ] Only accessible via secure channel
    - [ ] SSH with key based authentication
    - [ ] MFA/OTP/SSO SSH authentication
    - [ ] VPN
  - [ ] Brute-force protection (fail2ban)
  - [ ] Port-knocking ?
  - [x] Have access to all hosts in the infrastructure on a dedicated administration LAN
  - [ ] Implement proper Bastion solution (Boundary/Bastillion/The Bastion)
- **log**: log aggregation servers
  - [x] In admin LAN
  - [x] Receive logs from all hosts
  - [x] Transmit logs using UDP, TCP or RELP
  - [x] Rotate both hosts and aggregated logs
    - [ ] Review and "sync config with backup strategy
  - [ ] client: move queue settings to forwarding actions
  - [ ] Use improve template including priority, facility and severity
    - Sample format:
      ```rsyslog
      template(name="ExtendedFormat" 
            string="%syslogfacility-text%:%syslogseverity-text%:%timegenerated%:%HOSTNAME%:%msg%\n"
            )
      ```
    - Bind template to action
      ```rsyslog
      *.* action(type=”omfile” file=”/var/log/all-messages.log” template=”Name-of-your-template”)
      ```
  - [ ] Support sending logs in GELF format
  - [ ] Secure log transmission using TLS
  - [ ] Support redundancy and load-balancing
  - [ ] Store logs on persistent storage provided by storage hosts
  - [x] Only accessible from admin hosts
- **stor**: storage nodes
  - [x] Use Vagrant's local synced folders
  - [ ] Centralise persistent storage using NFS
  - [ ] Only accessible from admin hosts
  - [ ] On admin and storage networks
  - [ ] Provide persistent storage resources to all other hosts, services and applications on the storage network
- **bkp**: backup nodes
  - [ ] Only accessible from admin hosts
  - [ ] On admin and storage networks (requires storage network setup)
  - [ ] Provide files backup service to all other hosts on the storage network
  - [ ] Provide databases backup service to all other hosts on the storage network
  - [ ] Provide block backup service to all other hosts on the storage network
  - [ ] Provide backup gateway to cloud storage
- **dba**: database nodes
  - [x] Only accessible from admin hosts
  - [x] On admin, storage, and database networks
  - [x] Provide database services to all other services and applications on the database network
    - [x] Provide MariaDB service
    - [ ] Provide PostgreSQL service
    - [ ] Provide MongoDB service
    - [ ] Provide Redis service
- **app**: application nodes
  - [x] Only accessible from admin hosts
  - [x] On admin, storage, database, and front networks
  - [x] Provide application services to users through front services
    - [x] WordPress
- **pxy**: proxy nodes
  - [x] Only accessible from admin hosts
  - [x] On admin and front networks
  - [x] Route application services to users
    - [x] Reverse-proxy (nginx)
    - [x] Load-balancing (nginx)
    - [x] SSL termination (Let's Encrypt)


## Environment and configuration

Everything is configured with:

- the `.env` file for "public" parameters
- the `.env.priv` for secrets
  - included in `.gitignore` for privacy and security
  - `.env.priv.sample` provided for user to rename and fill-in with its
    own secrets.


## Scripts

- **`bootstrap.sh`**: initialize and launch project from scratch
  - **`python_setup.sh`**:
    - [x] Ensures required Python packages are installed
    - [x] Create project venv
    - [x] Upgrades pip and setuptools
    - [x] Installs requirements into venv
  - [ ] Setup Docker from  distro or upstream
  - **`docker_build_images.sh`**:
    - [x] builds images for all dockerfiles in `docker/` directory if run without argument, 
    - [x] builds a single image if passed the name of a container
    - [x] does nothing if passed `--no-rebuild`, can be used with `bootstrap.sh`
  - **`vagrant_setup.sh`**
    - [ ] Installs Vagrant from distro or upstream
    - [x] Installs required Vagrant plugins
  - [x] Launches projet using Vagrant `--no-parallel` option
- **`purge.sh`**: purge and delete all the things
  - **`vagrant_purge.sh`**
    - [x] Uninstalls and revoke SSL certificate before destroying project
    - [x] Destroys Vagrant project
    - [x] Removes `.vagrant/` directory
  - **`docker_prune.sh`**
    - [x] Removes Docker containers
    - [x] Removes Docker images
    - [x] Removes Docker networks
    - [x] Prunes `buildx`'s cache with `--prune-cache` option; can be used with `prune.sh`
  - **`data_purge.sh`**
    - [x] Removes logs
    - [x] Removes database
    - [x] Removes files
    - [x] Removes SSL certificates and keys
  - **`python_purge.sh`**
    - [x] Removes virtual environment
- **`pristine.sh`**: runs `purge.sh` and `bootstrap.sh` in one command.
  For when you want to restart fresh.


## Applications

Currently, only WordPress with MariaDB and NGINX is supported.


## Usage


## Configuration

Review and customize the configuration.
Required: copy/rename the `.env.priv.sample` to `.env.priv` and set your own secrets


### First run

Execute the `bootstrap.sh` script.
If no configuration error slipped in and everything goes fine, after a few minutes (or more, depending on your Internet connection and hardware), you should be able to

- access the application:
  - directly, through reverse proxy, or load balancer depending on chosen configuration options
    Load balancing is automatically enabled when app server number > 1
  - via bare HTTP or securely via HTTPS with Let's Encrypt managed certificate
- login to bastion host(s)
- check logs from all containers on log host(s)
- access backups of the whole infrastructure on backup host(s)
