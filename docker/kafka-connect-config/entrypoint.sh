#!/bin/bash

# Process templates
cp /etc/kafka-connect/templates/standalone.properties.template /etc/kafka-connect/config/standalone.properties
cp /etc/kafka-connect/templates/clickhouse.properties.template /etc/kafka-connect/config/clickhouse.properties

# Replace variables in standalone.properties
sed -i "s|\${CONNECT_BOOTSTRAP_SERVERS}|$CONNECT_BOOTSTRAP_SERVERS|g" /etc/kafka-connect/config/standalone.properties
sed -i "s|\${CONNECT_KEY_CONVERTER}|$CONNECT_KEY_CONVERTER|g" /etc/kafka-connect/config/standalone.properties
sed -i "s|\${CONNECT_VALUE_CONVERTER}|$CONNECT_VALUE_CONVERTER|g" /etc/kafka-connect/config/standalone.properties

# Replace variables in clickhouse.properties
sed -i "s|\${CLICKHOUSE_HOST}|$CLICKHOUSE_HOST|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CLICKHOUSE_DATABASE}|$CLICKHOUSE_DATABASE|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CLICKHOUSE_USER}|$CLICKHOUSE_USER|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CLICKHOUSE_PASSWORD}|$CLICKHOUSE_PASSWORD|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CLICKHOUSE_PORT}|$CLICKHOUSE_PORT|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CLICKHOUSE_PROTOCOL}|$CLICKHOUSE_PROTOCOL|g" /etc/kafka-connect/config/clickhouse.properties
sed -i "s|\${CONNECT_VALUE_CONVERTER}|$CONNECT_VALUE_CONVERTER|g" /etc/kafka-connect/config/clickhouse.properties

echo "Sleeping for 10 seconds as a hack to ensure other services are ready..."
sleep 10

exec /bin/connect-standalone /etc/kafka-connect/config/standalone.properties /etc/kafka-connect/config/clickhouse.properties 