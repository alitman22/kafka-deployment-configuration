# Docker Deployment Guide for Kafka Lab

This guide walks newcomers through deploying a complete 3-broker Kafka cluster with monitoring stack using Docker Compose.

## What You'll Deploy

- **3 ZooKeeper nodes** (ensemble for Kafka metadata)
- **3 Kafka brokers** (distributed cluster with replication)
- **Redpanda Console** (Web UI for Kafka management)
- **Prometheus** (metrics collection)
- **Grafana** (metrics visualization with pre-configured dashboards)
- **JMX Exporters** (3 instances to expose Kafka broker metrics)
- **Node Exporter** (system metrics)

## Prerequisites

- Docker Desktop or Docker Engine installed
- Docker Compose v2+ 
- 8GB+ RAM available for Docker
- Ports available: 9092-9094, 9100-9103, 3000, 5556-5558, 8080, 9090, 22181, 32181, 42181

## Quick Start

### Option 1: Using Ansible (Recommended)

1. **Install Ansible**:
   ```bash
   pip install ansible
   ```

2. **Install required collections**:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

3. **Deploy the Docker stack**:
   ```bash
   ansible-playbook -i inventories/docker/hosts.yml playbooks/deploy_docker_stack.yml
   ```

4. **Verify deployment**:
   ```bash
   cd /opt/kafka-lab  # Or your configured docker_project_dir
   docker compose ps
   ```

### Option 2: Manual Docker Compose

1. **Create runtime directory**:
   ```bash
   mkdir -p /tmp/kafka-lab-runtime
   cd /tmp/kafka-lab-runtime
   ```

2. **Copy configuration files** from repository:
   - `docker-compose.yml` (from roles/docker_stack/templates/docker-compose.yml.j2, processed)
   - `grafana/` directory with datasource.yml, dashboard.yml, and dashboards/
   - `prometheus/` directory with prometheus.yml
   - `jmx/` directory with config-kafka{1,2,3}.yml
   - `console/` directory with config.yml

3. **Start the stack in phases** (recommended for first-time deployment):
   
   **Phase 1 - ZooKeeper Ensemble**:
   ```bash
   docker compose up -d zookeeper1 zookeeper2 zookeeper3
   sleep 15  # Wait for ensemble formation
   docker compose ps
   ```

   **Phase 2 - Kafka Brokers**:
   ```bash
   docker compose up -d kafka1 kafka2 kafka3
   sleep 15  # Wait for broker election
   docker compose ps
   ```

   **Phase 3 - Monitoring & UI**:
   ```bash
   docker compose up -d jmx-exporter-kafka1 jmx-exporter-kafka2 jmx-exporter-kafka3 \
     node-exporter redpanda-console prometheus grafana
   sleep 15
   docker compose ps
   ```

4. **Verify all containers are running**:
   ```bash
   docker compose ps
   ```
   You should see 14 containers in "Up" state.

## Architecture Overview

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network                            │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  ZooKeeper1  │  │  ZooKeeper2  │  │  ZooKeeper3  │      │
│  │  :22181      │  │  :32181      │  │  :42181      │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         └─────────────────┴─────────────────┘              │
│                           │                                │
│         ┌─────────────────┴─────────────────┐              │
│         │                                   │              │
│  ┌──────▼───────┐  ┌──────────────┐  ┌──────▼───────┐      │
│  │   Kafka1     │  │   Kafka2     │  │   Kafka3     │      │
│  │   :9092      │  │   :9093      │  │   :9094      │      │
│  │   :9101 JMX  │  │   :9102 JMX  │  │   :9103 JMX  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         ├─────────────────┴─────────────────┤              │
│         │                                   │              │
│  ┌──────▼────────┐                  ┌───────▼────────┐     │
│  │  JMX Exporter │                  │    Redpanda    │     │
│  │  :5556-5558   │                  │    Console     │     │
│  └───────┬───────┘                  │    :8080       │     │
│          │                          └────────────────┘     │
│  ┌───────▼───────┐                                         │
│  │  Prometheus   │                                         │
│  │    :9090      │                                         │
│  └───────┬───────┘                                         │
│          │                                                 │
│  ┌───────▼───────┐                                         │
│  │   Grafana     │                                         │
│  │    :3000      │                                         │
│  └───────────────┘                                         │
└─────────────────────────────────────────────────────────────┘
```

### Port Mappings

| Service | Host Port | Container Port | Purpose |
|---------|-----------|----------------|---------|
| kafka1 | 9092 | 9092 | Client connections (EXTERNAL) |
| kafka1 | 9101 | 9101 | JMX metrics |
| kafka2 | 9093 | 9092 | Client connections (EXTERNAL) |
| kafka2 | 9102 | 9101 | JMX metrics |
| kafka3 | 9094 | 9092 | Client connections (EXTERNAL) |
| kafka3 | 9103 | 9101 | JMX metrics |
| zookeeper1 | 22181 | 2181 | Client connections |
| zookeeper2 | 32181 | 2181 | Client connections |
| zookeeper3 | 42181 | 2181 | Client connections |
| redpanda-console | 8080 | 8080 | Web UI |
| prometheus | 9090 | 9090 | Metrics API |
| grafana | 3000 | 3000 | Web UI |
| jmx-exporter-kafka1 | 5556 | 5556 | Prometheus exporter |
| jmx-exporter-kafka2 | 5557 | 5557 | Prometheus exporter |
| jmx-exporter-kafka3 | 5558 | 5558 | Prometheus exporter |
| node-exporter | 9100 | 9100 | System metrics |

**Note**: All Kafka brokers use **unified container ports** (9092 for client, 9101 for JMX) internally. Host port mappings (9092-9094, 9101-9103) allow external access to individual brokers.

### Listener Configuration

Each Kafka broker has two listeners:

- **INTERNAL** (port 19092): Inter-broker communication within Docker network
- **EXTERNAL** (port 9092 container): Client connections from host machine

Advertised listeners:
- kafka1: `localhost:9092`
- kafka2: `localhost:9093`
- kafka3: `localhost:9094`

## Accessing Services

### Redpanda Console (Kafka Web UI)
```
http://localhost:8080
```
**Features**:
- Browse topics and messages
- View consumer groups
- Monitor broker health
- Create/delete topics

### Grafana (Metrics Dashboards)
```
http://localhost:3000
```
**Default credentials**: admin / admin

**Pre-configured dashboards**:
1. **Kafka Metrics Dashboard**: Producer/consumer metrics, throughput, broker health
2. **Kafka Resources Dashboard**: CPU, memory, disk, JVM stats

### Prometheus (Raw Metrics)
```
http://localhost:9090
```
Query language (PromQL) for custom metrics exploration.

## Verifying the Deployment

### 1. Check Container Status
```bash
docker compose ps
```
All 14 containers should show "Up" status.

### 2. Check ZooKeeper Ensemble
```bash
# Check ensemble status
docker exec zookeeper1 zookeeper-shell localhost:2181 ls /brokers/ids
```
Should show: `[1, 2, 3]` (all broker IDs registered)

### 3. Check Kafka Cluster
```bash
# List brokers
docker exec kafka1 kafka-broker-api-versions --bootstrap-server kafka1:19092
```

### 4. Create Test Topic
```bash
# Create topic with replication factor 3
docker exec kafka1 kafka-topics --create \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 3 \
  --bootstrap-server kafka1:19092

# Describe topic to verify replication
docker exec kafka1 kafka-topics --describe \
  --topic test-topic \
  --bootstrap-server kafka1:19092
```

Expected output should show 3 partitions with 3 replicas each, all in-sync.

### 5. Test Message Production/Consumption
```bash
# Produce messages
docker exec -it kafka1 kafka-console-producer \
  --topic test-topic \
  --bootstrap-server kafka1:19092

# (Type some messages, press Ctrl+C to exit)

# Consume messages
docker exec -it kafka1 kafka-console-consumer \
  --topic test-topic \
  --from-beginning \
  --bootstrap-server kafka1:19092
```

## Configuration Files

### Grafana Datasource (`grafana/datasource.yml`)
Configures Prometheus as the default datasource for metrics visualization.

### Grafana Dashboard Provider (`grafana/dashboard.yml`)
Enables automatic dashboard provisioning from the dashboards directory.

### Grafana Dashboards (`grafana/dashboards/`)
- `kafka-metrics-dashboard.json`: Core Kafka operational metrics
- `kafka-resources-dashboard.json`: System resource utilization

### Prometheus Configuration (`prometheus/prometheus.yml`)
Scrape targets:
- node-exporter (system metrics)
- jmx-exporter-kafka1, jmx-exporter-kafka2, jmx-exporter-kafka3 (Kafka JMX metrics)

### JMX Exporter Configs (`jmx/config-kafka*.yml`)
Each file configures the JMX exporter to scrape metrics from its corresponding Kafka broker on port 9101 (unified).

### Redpanda Console Config (`console/config.yml`)
Broker connection strings for all 3 Kafka brokers using internal listener (19092).

## Startup Sequence Explained

The phased startup is important for cluster stability:

1. **ZooKeeper First**: Forms the ensemble (quorum) before Kafka needs it
2. **Kafka Second**: Brokers register with ZooKeeper, elect controller, form cluster
3. **Monitoring Last**: Once Kafka is stable, observability tools can start scraping metrics

**Why this matters**:
- ZooKeeper requires majority (2/3) to form quorum
- Kafka brokers fail to start if ZooKeeper is unavailable
- JMX exporters connect to Kafka JMX ports which only open after broker initialization

## Common Operations

### Stop the Stack
```bash
docker compose down
```

### Stop and Remove All Data
```bash
docker compose down -v  # Removes volumes (prometheus-data, grafana-data)
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f kafka1
docker compose logs -f zookeeper1
```

### Restart a Single Service
```bash
docker compose restart kafka2
```

### Scale Operations
To add a 4th Kafka broker, you would:
1. Add `kafka4` service definition to `docker-compose.yml`
2. Add corresponding `jmx-exporter-kafka4` service
3. Update Prometheus scrape config
4. Update Redpanda Console broker list

## Troubleshooting

### ZooKeeper Won't Form Ensemble
**Symptom**: ZooKeeper containers restart repeatedly

**Check**:
```bash
docker compose logs zookeeper1 zookeeper2 zookeeper3
```

**Common causes**:
- Incorrect `ZOOKEEPER_SERVERS` format (must be semicolon-separated)
- Port conflicts on host
- Insufficient memory

**Fix**: Ensure `ZOOKEEPER_SERVERS` uses format: `zookeeper1:2888:3888;zookeeper2:2888:3888;zookeeper3:2888:3888`

### Kafka Broker Fails to Start
**Symptom**: Kafka container exits or restarts

**Check**:
```bash
docker compose logs kafka1
```

**Common causes**:
- ZooKeeper not ready (start ZooKeeper first, wait 15s)
- Port conflicts (9092-9094 already in use)
- JMX port conflicts (9101-9103 already in use)

**Fix**: Use phased startup approach, verify no port conflicts

### JMX Exporter Can't Connect
**Symptom**: Prometheus shows exporter targets as "down"

**Check**:
```bash
docker compose logs jmx-exporter-kafka1
curl http://localhost:5556/metrics
```

**Common causes**:
- Kafka broker not fully started (wait longer)
- Incorrect JMX port in config file
- Network connectivity issue

**Fix**: Verify Kafka JMX ports are open:
```bash
docker exec kafka1 netstat -tuln | grep 9101
```

### Grafana Dashboards Not Loading
**Symptom**: Dashboards folder empty in Grafana UI

**Check**:
```bash
docker compose logs grafana
docker exec grafana ls -la /var/lib/grafana/dashboards/
```

**Common causes**:
- Dashboard JSON files not mounted correctly
- Dashboard provider path mismatch
- Permissions issue on volume mounts

**Fix**: Verify volume mounts in docker-compose.yml and dashboard.yml paths match

## Production Considerations

This Docker setup is for **development and testing only**. For production:

1. Use the Ansible production playbooks (`inventories/prod/`)
2. Deploy on dedicated Ubuntu 22.04 VMs
3. Enable TLS/SASL security (see main README.md)
4. Configure persistent volumes for Kafka data
5. Implement proper backup strategy
6. Set up cluster monitoring and alerting
7. Configure resource limits (CPU, memory) per broker
8. Review and harden firewall rules

See the main [README.md](README.md) for production deployment guidance.

## Advanced Topics

### Changing Replication Factors
Default settings in this stack:
- `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3`
- `KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3`
- `KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2`

These ensure high availability for internal Kafka topics.

### Adding Custom Kafka Configuration
Edit broker environment variables in `docker-compose.yml`. All `KAFKA_*` variables map to `server.properties` settings.

Example - increase log retention:
```yaml
environment:
  KAFKA_LOG_RETENTION_HOURS: 168  # 7 days
  KAFKA_LOG_RETENTION_BYTES: 1073741824  # 1GB
```

### Using External Kafka Clients
Connect from your host machine using advertised listeners:

```bash
# Producer
kafka-console-producer \
  --topic test-topic \
  --bootstrap-server localhost:9092,localhost:9093,localhost:9094

# Consumer
kafka-console-consumer \
  --topic test-topic \
  --bootstrap-server localhost:9092,localhost:9093,localhost:9094 \
  --from-beginning
```

**Note**: Use `localhost:9092-9094` from host, but `kafka1:19092` (INTERNAL listener) from other containers.

## Resources

- [Confluent Platform Documentation](https://docs.confluent.io/platform/current/overview.html)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Redpanda Console Documentation](https://docs.redpanda.com/current/reference/console/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## Getting Help

1. Check container logs: `docker compose logs <service-name>`
2. Review the main README.md for architecture details
3. Verify all prerequisites are met
4. Ensure no port conflicts on host machine
5. Try phased startup approach if services fail to initialize

## Clean Slate Restart

If you need to start completely fresh:

```bash
# Stop and remove everything
docker compose down -v

# Remove any orphaned containers
docker compose down --remove-orphans

# Verify nothing is running
docker ps -a | grep -E "kafka|zookeeper|prometheus|grafana|jmx|console"

# Start fresh with phased approach
docker compose up -d zookeeper1 zookeeper2 zookeeper3
sleep 15
docker compose up -d kafka1 kafka2 kafka3
sleep 15
docker compose up -d jmx-exporter-kafka1 jmx-exporter-kafka2 jmx-exporter-kafka3 \
  node-exporter redpanda-console prometheus grafana
```

---

**Last Updated**: March 2026  
**Confluent Platform Version**: 7.6.1  
**Docker Compose Version**: 3.9+
