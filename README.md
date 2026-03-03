# Kafka Deployment Configuration (Ansible, Role-Based)

Comprehensive role-based Ansible project to deploy:

- **Production**: 3-node Kafka brokers + 3-node Zookeeper ensemble on Ubuntu 22.04
- **Development/Staging**: Containerized equivalent stack with Docker Compose
- **Supporting services**: Redpanda Console, Kafka JMX Exporter, Node Exporter, Chrony
- **NAT exposure guidance**: pfSense NAT/firewall generated artifacts for external Kafka listener
- **Scale support**: add brokers and rebalance partitions

## Architecture

### Production (Ubuntu 22.04)

- `zookeeper` group: `zk-1..zk-3`
- `kafka` group: `kafka-1..kafka-3`
- `console` group: `console-1`
- `pfsense_docs` group: local generation of NAT artifacts

Kafka listener model:

- `INTERNAL://<private-ip>:9092` (inter-broker and internal clients)
- `EXTERNAL://<public-nat-ip>:19092` (external clients via pfSense NAT)

### Development/Staging (Docker)

- 3x Zookeeper containers
- 3x Kafka containers
- Redpanda Console container
- Node Exporter container
- 3x JMX exporter containers

## Repository layout

- `playbooks/prod.yml` - production installation
- `playbooks/docker.yml` - dockerized dev/staging stack
- `playbooks/scale_add_broker.yml` - scale-out run (serial)
- `roles/*` - modular services and infra
- `inventories/prod/*` - production inventory and vars
- `inventories/docker/*` - docker inventory and vars
- `scripts/rebalance-topics.sh` - partition reassignment generation
- `generated/` - pfSense NAT output artifacts (generated)

## Prerequisites

Control node:

- Ansible 2.15+
- Python 3.10+
- SSH access to Ubuntu nodes

Target prod nodes:

- Ubuntu 22.04+
- network reachability among brokers/ZK

Install collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Configure inventory

Update `inventories/prod/hosts.yml`:

- private IPs (`ansible_host`, `kafka_internal_ip`)
- external/NAT IPs (`kafka_external_ip`)
- broker IDs and zookeeper IDs

Tune global vars in `inventories/prod/group_vars/all.yml`.

## Deploy production

```bash
ansible-playbook -i inventories/prod/hosts.yml playbooks/prod.yml
```

## Deploy dev/staging docker stack

```bash
ansible-playbook -i inventories/docker/hosts.yml playbooks/docker.yml
```

## Scale out brokers

1. Add new broker host to `inventories/prod/hosts.yml` under `kafka` with next `kafka_broker_id`.
1. Run:

```bash
ansible-playbook -i inventories/prod/hosts.yml playbooks/scale_add_broker.yml
```

1. Rebalance partitions on a broker host:

```bash
chmod +x scripts/rebalance-topics.sh
BROKER_LIST="1,2,3,4" BOOTSTRAP="<broker>:9092" scripts/rebalance-topics.sh
```

## pfSense NAT artifacts

`playbooks/prod.yml` includes role `pfsense_nat`, generating:

- `generated/pfsense-nat-plan.md`
- `generated/pfsense-shellcmd.sh`

These provide exact WAN→LAN forwarding entries and firewall rule checklist based on your inventory.

## Validation

Run syntax + inventory checks:

```powershell
./scripts/validate.ps1
```

Optional runtime checks after deployment:

- Kafka metadata from internal client: `kcat -b <private-broker-ip>:9092 -L`
- Kafka metadata from external client: `kcat -b <nat-public-ip>:19092 -L`
- Node exporter: `http://<node>:9100/metrics`
- JMX exporter: `http://<broker>:9404/metrics`
- Redpanda Console: `http://<console-host>:8080`

## Notes

- Current templates use PLAINTEXT listeners for simplicity and demo readiness.
- For real production security, use TLS + SASL (or mTLS) and harden firewall ACLs.
