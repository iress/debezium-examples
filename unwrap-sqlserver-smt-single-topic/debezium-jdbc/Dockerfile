ARG DEBEZIUM_VERSION
FROM quay.io/debezium/connect:${DEBEZIUM_VERSION}
ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc

ARG POSTGRES_VERSION=42.2.23
ARG KAFKA_JDBC_VERSION=10.2.2
ARG CONFLUENT_TRANSFORMS_VERSION=1.4.3

# Deploy PostgreSQL JDBC Driver
RUN cd /kafka/libs && curl -sO https://jdbc.postgresql.org/download/postgresql-$POSTGRES_VERSION.jar

# Deploy Kafka Connect JDBC
RUN mkdir $KAFKA_CONNECT_JDBC_DIR && cd $KAFKA_CONNECT_JDBC_DIR &&\
	curl -sO https://packages.confluent.io/maven/io/confluent/kafka-connect-jdbc/$KAFKA_JDBC_VERSION/kafka-connect-jdbc-$KAFKA_JDBC_VERSION.jar

# Deploy Confluent Connect Transforms
RUN cd $KAFKA_CONNECT_PLUGINS_DIR &&\
	curl -sO https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/connect-transforms/versions/$CONFLUENT_TRANSFORMS_VERSION/confluentinc-connect-transforms-$CONFLUENT_TRANSFORMS_VERSION.zip &&\
	unzip confluentinc-connect-transforms-$CONFLUENT_TRANSFORMS_VERSION.zip &&\
	rm confluentinc-connect-transforms-$CONFLUENT_TRANSFORMS_VERSION.zip
