# Vagrant/Docker infrastructure for highly available Web Apps


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
- Hosts IPs are "stacked", south to north: Admin > Storage > Databases > Applications > Front [> DMZ]


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
- **log**: log aggregation servers
  - [x] In admin LAN
  - [x] Receive logs from all hosts
  - [x] Transmit logs using UDP, TCP or RELP
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
  - [ ] Only accessible from admin hosts
  - [ ] On admin and storage networks
  - [ ] Provide persistent storage resources to all other hosts, services and applications on the storage network
- **bkp**: backup nodes
  - [ ] Only accessible from admin hosts
  - [ ] On admin and storage networks
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

- **`bootstrap.sh`**: launch project from scratch
- **`prune.sh`**: purge and delete all the things
- **`pristine.sh`**: run purge.sh and bootstrap.sh in one command.
  For when you want to restart fresh.


## Applications

Currently, only WordPress is supported.


## Usage


## Configuration

Review and customize the configuration.
Required: copy/rename the `.env.priv.sample` and set your own secrets


### First run

Execute the `bootstrap.sh` script.
If no configuration error slipped in and everything goes fine, after a few minutes (or more, depending on your Internet connection and hardware), you should be able to login in the application
