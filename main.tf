

# provider kubernetes{
#     # If we're running in development mode, load the config file and 
#     # ignore the settings here. Otherwise, use the provided variables.
#     load_config_file = var.development == true ? true: false

#     host = "https://142.68.130.126"
#     client_certificate = var.CLIENT_CERT
#     client_key = var.CLIENT_KEY
#     cluster_ca_certificate = var.CA
# }

# # Create connectors for samples
# module "sample-data-connector" {
#     source = "git@gitlab.com:looking-glass1/kafka-connect-module.git"

#     #Variables
#     name = "sample"
    
#     depends_on = [kubernetes_deployment.kafka-connect]
# }

# # Create connectors for interlude
# module "interlude-data-connector" {
#     source = "git@gitlab.com:looking-glass1/kafka-connect-module.git"

#     #Variables
#     name = "interlude"
    
#     depends_on = [kubernetes_deployment.kafka-connect]
# }

# # Create connectors for stepping_stone
# module "stepping-stone-data-connector" {
#     source = "git@gitlab.com:looking-glass1/kafka-connect-module.git"

#     #Variables
#     name = "stepping-stone"
    
#     depends_on = [kubernetes_deployment.kafka-connect]
# }

# # Create connectors for vanguard
# module "vanguard-data-connector" {
#     source = "git@gitlab.com:looking-glass1/kafka-connect-module.git"

#     #Variables
#     name = "vanguard"
    
#     depends_on = [kubernetes_deployment.kafka-connect]
# }

# Deploy Kafka
resource "kubernetes_deployment" "kafka" {
    metadata{
        name = "kafka-deployment"
        labels = {
            app = "kafka"
        }
    }
    depends_on = [kubernetes_deployment.zookeeper]
    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "kafka"
            }
        }


        #Kafka pod
        template{
            metadata{
                name="kafka"
                labels = {
                    app = "kafka"
                }
            }

            spec{
                dns_policy = "ClusterFirstWithHostNet"
                # Kafka container
                container{
                    image = "bitnami/kafka:2.5.0"
                    name = "kafka-server"
                    
                    # Kafka Environment variables
                    env{
                        name = "KAFKA_BROKER_ID"
                        value = 1
                    }

                    env{
                        name = "KAFKA_ZOOKEEPER_CONNECT"
                        value = "zoo1:2181"
                    }
                     
                    env{
                        name = "ALLOW_PLAINTEXT_LISTENER"
                        value = "yes"
                    }

                    env{
                        name = "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP"
                        value = "CLIENT:PLAINTEXT,PLAINTEXT:PLAINTEXT"
                    }

                    env{
                        name = "KAFKA_CFG_LISTENERS"
                        value = "CLIENT://:9092,PLAINTEXT://:9093"
                    }

                    env{
                        name = "KAFKA_CFG_ADVERTISED_LISTENERS"
                        value = "CLIENT://localhost:9092,PLAINTEXT://kafka:9093"
                    }

                    env{
                        name = "KAFKA_INTER_BROKER_LISTENER_NAME"
                        value = "PLAINTEXT"
                    }

                    env{
                        name="KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE"
                        value="TRUE"
                    }

                    port{
                        container_port = 9092
                    }
                    port{
                        container_port = 9093
                    }
                }
            }
        }    
    }
}

# Deploy Kafka Connect
resource "kubernetes_deployment" "kafka-connect"{
    metadata{
        name = "kafka-connect-deployment"
        labels = {
            app = "kafka-connect"
        }
    }
    depends_on = [kubernetes_deployment.kafka, kubernetes_deployment.elassandra]
    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "connect"
            }
        }

        #Kafka Connect pod
        template{
            metadata{
                name="connect"
                labels = {
                    app = "connect"
                }
            }

            spec{
                dns_policy = "ClusterFirstWithHostNet"
                #Kafka Connect Container
                container{
                    image = "confluentinc/cp-kafka-connect:5.5.1"
                    name = "connect"

                    #Kafka Connect Environment variables
                    env{
                        name = "CONNECT_BOOTSTRAP_SERVERS"
                        value = "kafka:9093"
                    }

                    env{
                        name="CONNECT_GROUP_ID"
                        value="nims-consumers"
                    }

                    env{
                        name="CONNECT_CONFIG_STORAGE_TOPIC"
                        value = "nims-consumers-config"
                    }

                    env{
                        name ="CONNECT_OFFSET_STORAGE_TOPIC"
                        value = "nims-consumers-offsets"
                    }

                    env{
                        name="CONNECT_STATUS_STORAGE_TOPIC"
                        value="nims-consumers-status"
                    }

                    env{
                        name="CONNECT_VALUE_CONVERTER"
                        value="io.confluent.connect.avro.AvroConverter"
                    }

                    env{
                        name="CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL"
                        value="http://registry:9081"
                    }

                    env{
                        name="CONNECT_KEY_CONVERTER"
                        value="org.apache.kafka.connect.storage.StringConverter"
                    }

                    env{
                        name="CONNECT_REST_ADVERTISED_HOST_NAME"
                        value="localhost"
                    }

                    env{
                        name="CONNECT_REST_PORT"
                        value="8082"
                    }

                    env{
                        name="CONNECT_CONNECTOR_CLASS"
                        value="io.confluent.connect.elasticsearch.ElasticsearchSinkConnector"
                    }

                    env{
                        name="CONNECT_TASKS_MAX"
                        value="1"
                    }

                    env{
                        name="CONNECT_TOPICS"
                        value="tpg.generation.metrics"
                    }

                    env{
                        name="CONNECT_NAME"
                        value="nims-elasticsearch-connector"
                    }

                    env{
                        name="CONNECT_CONNECTION_URL"
                        value="http://elassandra:9200"
                    }

                    env{
                        name="CONNECT_TYPE_NAME"
                        value="_doc"
                    }

                    env{
                        name="CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR"
                        value="1"
                    }

                    env{
                        name="CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR"
                        value="1"
                    }

                    env{
                        name="CONNECT_STATUS_STORAGE_REPLICATION_FACTOR"
                        value="1"
                    }

                }
            }
        }
    }
}

# Deploy Kibana
resource "kubernetes_deployment" "kibana"{
    metadata{
        name = "kibana-deployment"
        labels = {
            app = "kibana"
        }
    }

    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "kibana"
            }
        }

        #Kibana pod
        template{
            metadata{
                name="kibana"
                labels = {
                    app = "kibana"
                }
            }

            spec{
                dns_policy = "ClusterFirstWithHostNet"
                #Kibana container
                container{
                    image = "docker.elastic.co/kibana/kibana-oss:6.8.9"
                    name="kibana"

                    env{
                        name = "ELASTICSEARCH_HOSTS"
                        value = "http://elassandra:9200"
                    }

                    env{
                        name = "SERVER_HOST"
                        value = "os-vm230.research.cs.dal.ca"
                    }

                    port{
                        container_port = 5601
                    }


                }
            }
        }
    }

}

# Deploy Elassandra 
resource "kubernetes_deployment" "elassandra"{
    metadata{
        name = "elassandra-deployment"
        labels = {
            app = "elassandra"
        }
    }
    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "elassandra"
            }
        }

        #Elassandra pod
        template{
            metadata{
                name="elassandra"
                labels = {
                    app = "elassandra"
                }
            }

            spec{
                dns_policy = "ClusterFirstWithHostNet"
                #Elassandra container
                container{
                    image = "strapdata/elassandra:6.8.4"
                    name = "elassandra"

                    #Elassandra Environment variables
                    env{
                        name = "CASSANDRA_LISTEN_ADDRESS"
                        value = "localhost"
                    }

                    #Elassandra ports
                    port{
                        container_port = 9300 # Elastic Search Transport
                    }

                    port{
                        container_port = 9200 # Elastic Search HTTP
                    }

                    port {
                        container_port = 9160 # Thrift service
                    }

                    port {
                        container_port = 9142 # Encrypted CQL
                    }

                    port {
                        container_port = 9042 # CQL
                    }

                    port {
                        container_port = 7199 # JMX
                    }

                    port {
                        container_port = 7001 # TLS intra-node communication
                    }

                    port {
                        container_port = 7000 # Intra-node communication
                    }

                    readiness_probe{
                        exec{
                            command =  [ "/bin/bash", "-c", "/ready-probe.sh" ]
                        }
                        initial_delay_seconds = 15
                        timeout_seconds = 5
                    }

                    volume_mount{
                        name = "elassandra-storage"
                        mount_path = "/var/lib/cassandra"
                    }
                }
                volume{
                    name = "elassandra-storage"
                    persistent_volume_claim{
                        claim_name = "elassandra-volume-claim"
                    }
                }
            }
        }
    }
}

# Deploy Schema Registry (for Avro)
resource "kubernetes_deployment" "avro-registry"{
    metadata{
        name = "avro-registry-deployment"
        labels = {
            app = "avro-registry"
        }
    }
    depends_on = [kubernetes_deployment.kafka]
    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "avro-registry"
            }
        }

        #Schema Registry Pod
        template{
            metadata{
                name = "avro-registry"
                labels = {
                    app = "avro-registry"
                }
            }

            spec{
                dns_policy = "ClusterFirstWithHostNet"
                #Schema Registry container
                container{
                    image = "confluentinc/cp-schema-registry:5.5.1"
                    name = "avro-registry"

                     env{
                        name = "SCHEMA_REGISTRY_HOST_NAME"
                        value = "localhost"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL"
                        value = "zoo1:2181"
                    }

                    # Allow schema changes... this may be a mistake.
                    env{
                        name = "SCHEMA_REGISTRY_SCHEMA_COMPATIBILITY_LEVEL"
                        value = "none"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_LISTENERS"
                        value = "http://0.0.0.0:9081"
                    }
                }
            }
        }
    }
}

# Deploy Zookeeper
resource "kubernetes_deployment" "zookeeper" {
    metadata{
        name = "zookeeper-deployment"
        labels = {
            app = "zookeeper"
        }
    }

    spec{
        replicas = 1

        selector{
            match_labels = {
                app = "zookeeper"
            }
        }

        #Zookeeper pod
        template{
            metadata{
                name="zookeeper"
                labels = {
                    app = "zookeeper"
                }
            }

            spec{
                # Zookeeper container
                container{
                    image = "bitnami/zookeeper:3.6.1"
                    name = "zookeeper-server"

                    env{
                        name="ZOOKEEPER_ID"
                        value=1
                    }

                    env{
                        name="ZOOKEEPER_SERVER_1"
                        value="zoo1"
                    }

                    env{
                        name="ALLOW_ANONYMOUS_LOGIN"
                        value="yes"
                    }

                    
                    port{
                        container_port = 2181
                    }
                    
                }
      
            }
        }
    }


}

#Zookeeper service
resource "kubernetes_service" "zookeeper-service"{
    metadata{
        name = "zoo1"
        labels = {
            app = "zookeeper"
        }
    }
    spec{
        port{
            name = "client"
            port = 2181
            target_port = 2181
            node_port = 30700
        }

        selector = {
                app = "zookeeper"
        }
        type = "NodePort"
        external_traffic_policy = "Local"
    }
}

#Kafka service
resource "kubernetes_service" "kafka_service"{
    metadata{
        name = "kafka"
        labels = {
            app = "kafka"
        }
    }
    spec{
        port{
            name = "kafka"
            port = 9092
            target_port = 9092
            node_port = 30701
        }

        port{
            name = "kafka2"
            port = 9093
            target_port = 9093
        }
        
        selector = {
            app = "kafka"
        }
        
        type = "NodePort"
        external_traffic_policy = "Local"

    }
}

#Schema Registry service
resource "kubernetes_service" "avro_registry"{
    metadata{
        name = "registry"
        labels = {
            app = "registry"
        }
    }
    spec{
        port{
            name = "avro-registry"
            port = 9081
            target_port = 9081
            node_port = 30702
        }

        selector = {
            app = "avro-registry"
        }

        type = "NodePort"
        external_traffic_policy = "Local"
    }
}

#Elassandra Service
resource "kubernetes_service" "elassandra_service"{
    metadata{
        name = "elassandra"
        labels = {
            app = "elassandra"
        }
    }
    spec{

        selector = {
            app = "elassandra"
        }

        # Elastic Search Transport
        port{
            name = "elastic-transport"
            port = 9300
            target_port = 9300
            node_port = 30703
        }

        # Elastic Search HTTP
        port{
            name = "elastic-http"
            port = 9200
            target_port = 9200
            node_port = 30704
        }

        # Thrift Service
        port{
            name = "thrift-service"
            port = 9160
            target_port = 9160
            node_port = 30705
        }

        # Encrypted CQL
        port{
            name = "encrypted-cql"
            port = 9142
            target_port = 9142
            node_port = 30706
        }

        # CQL
        port{
            name = "cql"
            port = 9042
            target_port = 9042
            node_port = 30707
        }

        # JMX
        port{
            name = "jmx"
            port = 7199
            target_port = 7199
            node_port = 30708
        }

        # TLS intra-node communication
        port{
            name = "intra-tls"
            port = 7001
            target_port = 7001
            node_port = 30709
        }

        # Intra-node communication
        port{
            name = "intra"
            port = 7000
            target_port = 7000
            node_port = 30710
        }

        type = "NodePort"
        external_traffic_policy = "Local"
    }
}

#Kafka Connect Service
resource "kubernetes_service" "kafka_connect_service"{
    metadata{
        name="connect"
        labels={
            app = "connect"
        }
    }

    spec{
        port{
            name="connect"
            port=8082
            target_port=8082
        }

        selector = {
            app = "connect"
        }
        type = "NodePort"
        external_traffic_policy = "Local"
    }
}

resource "kubernetes_service" "kibana_service"{
    metadata{
        name="kibana"
        labels={
            app = "kibana"
        }
    }
    spec{
        port{
            name="kibana"
            port=5601
        }

        selector = {
            app = "kibana"
        }
        
    }
}

# Kibana Ingress 
resource "kubernetes_ingress" "kibana_ingress"{
    metadata {
      name = "kibana-ingress"
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
      }
    }

    spec {
      rule {
          host = "os-vm230.research.cs.dal.ca"
        http{
            path{
                path = "/"
                backend{
                    service_name = kubernetes_service.kibana_service.metadata.0.name
                    service_port = 5601
                }
            }
        }
      }

    }
}

resource "kubernetes_persistent_volume" "elassandra_volume"{
    metadata{
        name = "elassandra-pv"
    }
    spec{
        capacity = {
            storage = var.elassandra_volume_size
        }
        access_modes = ["ReadWriteMany"]
        storage_class_name = "standard"
        node_affinity{
            required{
                node_selector_term {
                    match_expressions {
                        key = "kubernetes.io/hostname"
                        operator = "In"
                        values = [var.elassandra_data_node]
                    }
                }
            }
        }
        persistent_volume_source{
            local{
                path = var.elassandra_data_path
            }
        }
    }
}



resource "kubernetes_persistent_volume_claim" "elassandra_pvc"{
    metadata {
        name = "elassandra-volume-claim"
    }
    spec{
        access_modes = ["ReadWriteMany"]
        storage_class_name = "standard"
        resources {
            requests = {
                storage = var.elassandra_volume_size
            }
        }
        volume_name = kubernetes_persistent_volume.elassandra_volume.metadata.0.name
    }
}

