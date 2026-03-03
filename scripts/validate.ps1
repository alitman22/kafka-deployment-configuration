$ErrorActionPreference = 'Stop'

Write-Host 'Checking Ansible version...'
ansible --version | Out-Host

Write-Host 'Installing/ensuring required collections...'
ansible-galaxy collection install -r requirements.yml | Out-Host

Write-Host 'Syntax check: production playbook'
ansible-playbook -i inventories/prod/hosts.yml playbooks/prod.yml --syntax-check | Out-Host

Write-Host 'Syntax check: docker playbook'
ansible-playbook -i inventories/docker/hosts.yml playbooks/docker.yml --syntax-check | Out-Host

Write-Host 'Syntax check: scale playbook'
ansible-playbook -i inventories/prod/hosts.yml playbooks/scale_add_broker.yml --syntax-check | Out-Host

Write-Host 'Inventory parse: production'
ansible-inventory -i inventories/prod/hosts.yml --graph | Out-Host

Write-Host 'Inventory parse: docker'
ansible-inventory -i inventories/docker/hosts.yml --graph | Out-Host

Write-Host 'Validation completed successfully.'
