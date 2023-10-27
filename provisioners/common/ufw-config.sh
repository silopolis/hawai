#!/bin/bash

# TODO Create common UFW provisioner script
# TODO Add firewall configuration to all guests

## logs
ufw logging on
ufw default deny
ufw limit ssh
ufw allow ssh from "$VAG_NET_ADDR/$VAG_NET_CIDR"
ufw allow 514/udp from "$ADM_NET_ADDR/$ADM_NET_CIDR"
ufw allow 514/tcp
ufw reload 