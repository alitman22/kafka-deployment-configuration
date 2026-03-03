# Kafka Monitoring Stack - Metrics Coverage

## Overview
Your Kafka deployment now has comprehensive monitoring with 3 specialized Grafana dashboards covering all critical metrics.

## Port Mappings Summary

### Kafka Brokers
All brokers have **unified container ports** with unique host mappings:

| Broker | Client Port (Host→Container) | JMX Port (Host→Container) | Internal Listener |
|--------|------------------------------|---------------------------|-------------------|
| kafka1 | 9092:9092                    | 9101:9101                 | kafka1:19092      |
| kafka2 | 9093:9092                    | 9102:9101                 | kafka2:19092      |
| kafka3 | 9094:9092                    | 9103:9101                 | kafka3:19092      |

### JMX Exporters
| Exporter | Port | Scrapes From |Status |
|----------|------|--------------|-------|
| jmx-exporter-kafka1 | 5556 | kafka1:9101 | ✅ Active |
| jmx-exporter-kafka2 | 5557 | kafka2:9101 | ✅ Active |
| jmx-exporter-kafka3 | 5558 | kafka3:9101 | ✅ Active |

### Monitoring Services
| Service | Port | Purpose |
|---------|------|---------|
| Prometheus | 9090 | Metrics aggregation |
| Grafana | 3000 | Visualization |
| Node Exporter | 9100 | System metrics |
| Redpanda Console | 8080 | Kafka UI |

## Grafana Dashboards

### 1. Kafka Metrics Dashboard
**Focus**: Core operational metrics and producer/consumer performance

**Panels**:
- **Messages In/sec** - Cluster-wide message ingestion rate
- **Network Throughput** - Bytes in/out per broker
- **Active Brokers** - Health check (shows 3/3 when healthy)
- **Total Partitions** - Cluster partition count
- **Under-Replicated Partitions** - Replication health (should be 0)
- **Offline Replicas** - Critical health indicator (should be 0)
- **Leader Count per Broker** - Leadership distribution
- **Producer/Consumer Latency** - p99 request latency
- **Producer/Consumer Request Rate** - Throughput per operation
- **Active Controller** - Controller election status
- **Log Size by Topic** - Disk usage per topic

**Key Metrics**:
- `kafka_server_brokertopicmetrics_messagesin_total`
- `kafka_server_brokertopicmetrics_bytesin_total`
- `kafka_server_brokertopicmetrics_bytesout_total`
- `kafka_server_replicamanager_partitioncount`
- `kafka_server_replicamanager_underreplicatedpartitions`
- `kafka_server_replicamanager_offlinereplicacount`
- `kafka_server_replicamanager_leadercount`
- `kafka_network_requestmetrics_totaltimems`
- `kafka_network_requestmetrics_requests_total`
- `kafka_controller_kafkacontroller_activecontrollercount`
- `kafka_log_log_size`

### 2. Kafka Resources Dashboard
**Focus**: System resources, JVM health, and infrastructure monitoring

**Panels**:
- **CPU Usage** - Per-broker CPU utilization
- **Memory Usage** - Broker memory consumption
- **Disk Usage** - Storage capacity and I/O
- **JVM Heap Memory** - Java heap usage per broker
- **JVM Non-Heap Memory** - JVM metadata and code cache
- **JVM Thread Count** - Thread pool metrics
- **Garbage Collection** - GC pause time and frequency
- **Network I/O** - Network traffic patterns
- **Broker Uptime** - Availability tracking
- **JMX Exporter Health** - Metrics scraping status

**Key Metrics**:
- `process_cpu_usage`
- `jvm_memory_used_bytes`
- `jvm_memory_max_bytes`
- `jvm_threads_current`
- `jvm_gc_pause_seconds_count`
- `jvm_gc_pause_seconds_sum`
- System disk/network metrics from node-exporter

### 3. Kafka Cluster Health & Performance (NEW)
**Focus**: Advanced cluster health, replication, ISR, errors, and operational metrics

**Critical Health Indicators** (Top Row):
- **Active Brokers** - Real-time broker availability (3 expected)
- **Under-Replicated Partitions** - Replication lag indicator
- **Offline Replicas** - Data availability issues
- **Controller Status** - Cluster coordination health
- **Total Partitions** - Cluster scale
- **Messages In/sec** - Real-time throughput

**Advanced Panels**:

**Message & Network Metrics**:
- **Message In Rate per Broker** - Per-broker ingestion with mean/max/current
- **Network Throughput** - Bytes in/out per broker

**Replication Health**:
- **Broker Partition & Replication Status** (Table) - Shows:
  - Partitions per broker
  - Leader count
  - Under-replicated partitions
  - Offline replicas
- **ISR Shrink/Expand Rate** - In-Sync Replica changes indicating network or broker issues

**Performance Metrics**:
- **Request Latency** - p50 and p99 for Produce and Fetch operations
- **Failed Request Rate** - Failed produce/fetch requests per broker
- **Log Flush Rate** - Disk write performance

**Operational Metrics**:
- **Log Size by Topic** - Storage growth per topic
- **Purgatory Size** - Delayed operations (Fetch/Produce waiting for completion)
- **ZooKeeper Connection Events** - ZK session stability

**Key Advanced Metrics**:
- `kafka_server_replicamanager_isrshrinks_total`
- `kafka_server_replicamanager_isrexpands_total`
- `kafka_server_brokertopicmetrics_failedfetchrequests_total`
- `kafka_server_brokertopicmetrics_failedproducerequests_total`
- `kafka_log_logflushstats_logflushratemstotal_rate_m1_rate`
- `kafka_server_delayedoperationpurgatory_purgatorysize`
- `kafka_server_sessionexpirelistener_zookeepersyncconnects_total`
- `kafka_server_sessionexpirelistener_zookeeperdisconnects_total`

## Metrics Flow Architecture

```
┌──────────────┐
│ Kafka Broker │ ──┐
│  JMX:9101    │   │
└──────────────┘   │
                   │
┌──────────────┐   │    ┌────────────────┐
│ Kafka Broker │ ──┼───>│ JMX Exporters  │
│  JMX:9101    │   │    │  :5556-5558    │
└──────────────┘   │    └────────┬───────┘
                   │             │
┌──────────────┐   │             │
│ Kafka Broker │ ──┘             │
│  JMX:9101    │                 │
└──────────────┘                 │
                                 │
┌──────────────┐                 │
│ Node Exporter│                 │
│    :9100     │                 │
└──────────┬───┘                 │
           │                     │
           └──────────┬──────────┘
                      │
                      ▼
              ┌──────────────┐
              │  Prometheus  │
              │    :9090     │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │   Grafana    │
              │    :3000     │
              └──────────────┘
```

## Accessing Monitoring

### Grafana (Primary Dashboard UI)
```
URL: http://localhost:3000
Username: admin
Password: admin
```

**Available Dashboards**:
1. Kafka Metrics Dashboard - Core metrics
2. Kafka Resources Dashboard - System resources
3. Kafka Cluster Health & Performance - Advanced health monitoring

### Prometheus (Raw Metrics & Queries)
```
URL: http://localhost:9090
```

**Useful PromQL Queries**:

Check all JMX targets status:
```promql
up{job="kafka_jmx_exporter"}
```

Total cluster message rate:
```promql
sum(rate(kafka_server_brokertopicmetrics_messagesin_total[5m]))
```

Average request latency:
```promql
avg(kafka_network_requestmetrics_totaltimems{quantile="0.99"})
```

Under-replicated partitions:
```promql
sum(kafka_server_replicamanager_underreplicatedpartitions)
```

### Redpanda Console (Kafka Management UI)
```
URL: http://localhost:8080
```

Browse topics, consumer groups, and broker status.

## Health Check Procedures

### Daily Monitoring
Check these Grafana panels daily:
1. **Active Brokers** - Should show 3
2. **Under-Replicated Partitions** - Should be 0
3. **Offline Replicas** - Should be 0
4. **Failed Request Rate** - Should be near 0

### Performance Monitoring
Watch these for performance issues:
1. **Request Latency p99** - Spike indicates slow broker
2. **ISR Shrink Rate** - Frequent shrinks mean network/broker issues
3. **Purgatory Size** - Growing purgatory means slow consumers
4. **Log Flush Rate** - Slow flushes indicate disk issues

### Troubleshooting

**Under-Replicated Partitions > 0**:
- Check broker logs: `docker logs kafka1`
- Verify network connectivity between brokers
- Check disk I/O performance

**High Request Latency**:
- Check JVM GC pauses in Resources Dashboard
- Monitor CPU/Memory usage
- Review disk I/O metrics

**Failed Requests**:
- Check producer/consumer configurations
- Verify topic replication factor settings
- Review broker logs for errors

**JMX Exporter Down**:
```bash
# Check exporter logs
docker logs jmx-exporter-kafka1

# Verify broker JMX port is accessible
docker exec kafka1 netstat -tuln | grep 9101

# Test metrics endpoint
curl http://localhost:5556/metrics | grep kafka_server
```

## Alert Recommendations

Configure Grafana alerts for:

**Critical Alerts**:
- Active Brokers < 3
- Under-Replicated Partitions > 0
- Offline Replicas > 0
- Controller Count != 1

**Warning Alerts**:
- Request Latency p99 > 100ms
- Failed Request Rate > 0.1 per second
- ISR Shrink Rate > 1 per minute
- JVM Heap Usage > 80%

**Info Alerts**:
- Disk Usage > 70%
- Message In Rate drops > 50% from baseline

## Metric Retention

**Prometheus**:
- Default retention: 15 days
- Storage location: Docker volume `prometheus-data`

**Grafana**:
- Dashboard configs: Docker volume `grafana-data`
- Data source: Prometheus

## Backup Considerations

To backup monitoring configuration:
```bash
# Backup Prometheus config
docker cp prometheus:/etc/prometheus/prometheus.yml ./backup/

# Backup Grafana dashboards
docker exec grafana tar czf - /var/lib/grafana/dashboards | cat > ./backup/grafana-dashboards.tar.gz

# Backup volumes
docker run --rm -v kafka-lab-runtime_prometheus-data:/data -v $(pwd):/backup busybox tar czf /backup/prometheus-data-backup.tar.gz /data
```

## Performance Tuning Metrics

Monitor these for capacity planning:

**Storage Growth**:
- `kafka_log_log_size` - Plan for disk expansion
- Topic retention settings vs. growth rate

**Throughput Capacity**:
- Peak `kafka_server_brokertopicmetrics_messagesin_total` rate
- Network bandwidth utilization
- CPU usage during peak load

**Consumer Lag** (requires consumer group monitoring):
- Consumer lag metrics via Redpanda Console
- Set up consumer group lag exporters for Prometheus

## Next Steps

1. **Configure Alerting**:
   - Set up Grafana alert rules
   - Configure notification channels (email, Slack, PagerDuty)

2. **Consumer Lag Monitoring**:
   - Deploy Burrow or Kafka Lag Exporter
   - Add consumer group lag dashboard

3. **Long-term Storage**:
   - Configure Prometheus remote write to long-term storage (Thanos, Cortex, VictoriaMetrics)

4. **Custom Dashboards**:
   - Create application-specific dashboards
   - Add business metric panels

5. **Load Testing**:
   - Use metrics during load tests to establish baselines
   - Document normal operating ranges for each metric

---

**Documentation Version**: 1.0  
**Last Updated**: March 3, 2026  
**Kafka Version**: Confluent Platform 7.6.1  
**Monitoring Stack**: Prometheus 2.54.1, Grafana 11.2.0
