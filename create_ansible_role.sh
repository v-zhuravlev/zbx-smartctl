#!/bin/bash
ANSIBLE_ROLE_DIR=./ansible-role-zabbix-smartmontools

cp ./discovery-scripts/nix/smartctl-disks-discovery.pl $ANSIBLE_ROLE_DIR/files/
cp ./sudoers_zabbix_smartctl $ANSIBLE_ROLE_DIR/files/
cp ./zabbix_smartctl.conf $ANSIBLE_ROLE_DIR/files/
