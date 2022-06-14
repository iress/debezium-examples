# Debezium Unwrap SQL Server SMT Single Topic Demo

This setup is going to demonstrate how to receive events from a SQL Server database and stream them down to a PostgreSQL database using the [Debezium Event Flattening SMT](https://debezium.io/docs/configuration/event-flattening/). It is also going to demonstrate how to use a single topic to stream the data (rather than one topic per table) using the [Debezium Topic Routing SMT](https://debezium.io/docs/configuration/topic-routing/).

## Table of Contents

* [JDBC Sink](#jdbc-sink)
  * [Topology](#topology)
  * [Usage](#usage)
    * [New record](#new-record)
    * [Record update](#record-update)
    * [Record delete](#record-delete)

## JDBC Sink

### Topology

```text
                   +-------------+
                   |             |
                   | SQL Server  |
                   |             |
                   +------+------+
                          |
                          |
                          |
          +---------------v------------------+
          |                                  |
          |           Kafka Connect          |
          |   (Debezium, JDBC connector)     |
          |                                  |
          +---------------+------------------+
                          |
                          |
                          |
                          |
                  +-------v--------+
                  |                |
                  |   PostgreSQL   |
                  |                |
                  +----------------+


```

We are using Docker Compose to deploy following components

* SQL Server
* Kafka
  * ZooKeeper
  * Kafka Broker
  * Kafka Connect with [Debezium](https://debezium.io/) and  [JDBC](https://github.com/confluentinc/kafka-connect-jdbc) Connector
* PostgreSQL

To allow streaming via a single topic:

* The source connector uses the [ByLogicalTableRouter](https://debezium.io/docs/configuration/topic-routing/) transform to change the topic name from `dbserver1.dbo.{table_name}` to `inventory`, and to insert a `__dbz__physicalTableIdentifier` field into the key of each record. This key field allows the sink connector to identify which table each record is from, and ensures keys for records from different tables are unique throughout the topic.
* The sink connector writes to tables based on the topic name. The [ExtractTopic](https://docs.confluent.io/platform/current/connect/transforms/extracttopic.html) transform makes the connector use the table name in key field `__dbz__physicalTableIdentifier` as the topic name instead of `inventory`. The [ReplaceField](https://docs.confluent.io/platform/current/connect/transforms/replacefield.html) transform drops the `__dbz__physicalTableIdentifier` field from the key to prevent it being written to the tables.

### Usage

How to run:

```shell
# Start the application
export DEBEZIUM_VERSION=1.8
docker-compose up

# Start PostgreSQL connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @sink.json

# Start SQL Server connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @source.json
```

Check contents of the SQL Server database:

```shell
docker-compose exec sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD -d inventory -Q "select * from customers" -Y 24'
id          first_name               last_name                email                   
----------- ------------------------ ------------------------ ------------------------
       1001 Sally                    Thomas                   sally.thomas@acme.com   
       1002 George                   Bailey                   gbailey@foobar.com      
       1003 Edward                   Walker                   ed@walker.com           
       1004 Anne                     Kretchmar                annek@noanswer.org      
```

Verify that the PostgreSQL database has the same content:

```shell
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB -c "select * from customers"'
  id  | first_name | last_name |         email         
------+------------+-----------+-----------------------
 1001 | Sally      | Thomas    | sally.thomas@acme.com
 1002 | George     | Bailey    | gbailey@foobar.com
 1003 | Edward     | Walker    | ed@walker.com
 1004 | Anne       | Kretchmar | annek@noanswer.org
(4 rows)
```

#### New record

Insert a new record into SQL Server:

```shell
docker-compose exec sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD -d inventory'
1> insert into customers values('John', 'Doe', 'john.doe@example.com')
2> GO

(1 rows affected)
```

Verify that PostgreSQL contains the new record:

```shell
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB -c "select * from customers"'
  id  | first_name | last_name |         email         
------+------------+-----------+-----------------------
...
 1005 | John       | Doe       | john.doe@example.com
(5 rows)
```

#### Record update

Update a record in SQL Server:

```shell
1> update customers set first_name='Jane', last_name='Roe' where last_name='Doe'
2> GO

(1 rows affected)
```

Verify that record in PostgreSQL is updated:

```shell
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB -c "select * from customers"'
  id  | first_name | last_name |         email         
------+------------+-----------+-----------------------
...
 1005 | Jane       | Roe       | john.doe@example.com
(5 rows)
```

#### Record delete

Delete a record in SQL Server:

```shell
1> delete from customers where email='john.doe@example.com'
2> GO

(1 rows affected)
```

Verify that record in PostgreSQL is deleted:

```shell
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB -c "select * from customers"'
  id  | first_name | last_name |         email         
------+------------+-----------+-----------------------
...
(4 rows)
```

As you can see there is no longer a 'Jane Roe' as a customer.

End application:

```shell
# Shut down the cluster
docker-compose down
```
