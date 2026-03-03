#!/usr/bin/env bash
set -euo pipefail

echo "Checking Ansible version"
ansible --version

echo "Installing/ensuring required collections"
ansible-galaxy collection install -r requirements.yml

echo "Syntax check: production"
ansible-playbook -i inventories/prod/hosts.yml playbooks/prod.yml --syntax-check

echo "Syntax check: docker"
ansible-playbook -i inventories/docker/hosts.yml playbooks/docker.yml --syntax-check

echo "Syntax check: scale"
ansible-playbook -i inventories/prod/hosts.yml playbooks/scale_add_broker.yml --syntax-check

echo "Inventory parse: production"
ansible-inventory -i inventories/prod/hosts.yml --graph

echo "Inventory parse: docker"
ansible-inventory -i inventories/docker/hosts.yml --graph

echo "Validation completed successfully"
