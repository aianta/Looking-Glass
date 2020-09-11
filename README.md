Manages the infrastructure required to run 'Looking Glass'. A comprehensive
general logging, analysis and visualization tool for NIMS Lab research.
 
 Principle components are:
  - Apache Kafka
  - Elassandra (Cassandra + Elastic Search)
  - Kibana 
  
 Additional, supporting components are:
  - Zookeeper (required by kafka)
  - Schema Registry (for Avro Schemas)
  - Kafka Elasticsearch Connector (Ingesting data into elastic search)
 
 