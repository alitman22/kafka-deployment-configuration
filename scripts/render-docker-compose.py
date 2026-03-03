#!/usr/bin/env python3
"""Render docker-compose.yml.j2 template with inventory variables."""

import yaml
from jinja2 import Environment, FileSystemLoader
from pathlib import Path

# Load variables from inventory
repo_root = Path(__file__).parent.parent
inventory_vars_file = repo_root / 'inventories' / 'docker' / 'group_vars' / 'all.yml'

with open(inventory_vars_file, 'r') as f:
    variables = yaml.safe_load(f)

# Setup Jinja2 environment
template_dir = repo_root / 'roles' / 'docker_stack' / 'templates'
env = Environment(loader=FileSystemLoader(str(template_dir)))
template = env.get_template('docker-compose.yml.j2')

# Render template
rendered = template.render(**variables)

# Output to stdout
print(rendered)
