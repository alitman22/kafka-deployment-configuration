#!/usr/bin/env bash
set -euo pipefail

KAFKA_BIN=${KAFKA_BIN:-/opt/kafka/bin}
BOOTSTRAP=${BOOTSTRAP:-127.0.0.1:9092}
BROKER_LIST=${BROKER_LIST:-1,2,3,4}
TOPICS_JSON=${TOPICS_JSON:-/tmp/topics-to-move.json}
PLAN_JSON=${PLAN_JSON:-/tmp/reassignment-plan.json}

cat > "$TOPICS_JSON" <<'JSON'
{
  "version": 1,
  "topics": [
    {"topic": "__consumer_offsets"}
  ]
}
JSON

"${KAFKA_BIN}/kafka-reassign-partitions.sh" \
  --bootstrap-server "$BOOTSTRAP" \
  --topics-to-move-json-file "$TOPICS_JSON" \
  --broker-list "$BROKER_LIST" \
  --generate > "$PLAN_JSON"

echo "Generated reassignment plan at $PLAN_JSON"
echo "Review and apply with --execute using kafka-reassign-partitions.sh"
