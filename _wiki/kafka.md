---
title: "Apache Kafka"
date: 2020-09-04 10:30:08 +03:00
last_modified_at: 2022-03-29 10:42:58 +03:00
---

## Docker Setup

``` yaml
  #
  # Kafka config taken from:
  # https://raw.githubusercontent.com/bitnami/bitnami-docker-kafka/master/docker-compose.yml
  #

  zookeeper:
    image: bitnami/zookeeper:latest
    container_name: zookeeper
    networks: [ main ]
    ports:
      - '2181:2181'
    volumes:
      - 'zookeeper_data:/bitnami'
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes

  kafka:
    image: bitnami/kafka:latest
    container_name: kafka
    networks: [ main ]
    ports:
      - '9092:9092'
    volumes:
      - 'kafka_data:/bitnami'
    environment:
      # - KAFKA_BROKER_ID=1
      - KAFKA_LISTENERS=PLAINTEXT://:9092
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://127.0.0.1:9092
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - ALLOW_PLAINTEXT_LISTENER=yes
    depends_on:
      - zookeeper
```

## Utils

To create topics:

``` sh
docker exec -it kafka /opt/bitnami/kafka/bin/kafka-topics.sh \
    --create \
    --zookeeper zookeeper:2181 \
    --replication-factor 1 \
    --partitions 1 \
    --topic test
```

To view messages pushed to a topic:

``` sh
docker exec -it kafka /opt/bitnami/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --from-beginning \
  --topic test
```

To push messages on a topic:

``` sh
docker exec -it kafka /opt/bitnami/kafka/bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic test
```
