

# provider kubernetes{
#     # If we're running in development mode, load the config file and 
#     # ignore the settings here. Otherwise, use the provided variables.
#     load_config_file = var.development == true ? true: false

#     host = "https://142.68.130.126"
#     client_certificate = var.CLIENT_CERT
#     client_key = var.CLIENT_KEY
#     cluster_ca_certificate = var.CA
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
                # https://github.com/bitnami/bitnami-docker-kafka
                container{
                    image = "bitnami/kafka:2.5.0"
                    name = "kafka-server"

                    resources {
                      requests = {
                        cpu = "16" #16 cores
                        memory = "16G" #16GB
                      }
                    }

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
                       # value = "CLIENT://localhost:9092,PLAINTEXT://kafka:9093"
                        value = "CLIENT://os-vm230.research.cs.dal.ca:9092,PLAINTEXT://kafka:9093"
                    }

                    env{
                        name = "KAFKA_INTER_BROKER_LISTENER_NAME"
                        value = "PLAINTEXT"
                    }

                    env{
                        name="KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE"
                        value="TRUE"
                    }

                    # If we're gonna send massive TPG graphs over kafka we're gonna need a bigger messages
                    env{
                        name="KAFKA_CFG_REPLICA_FETCH_MAX_BYTES"
                        value=31457280 #30MB
                    }

                    env{
                        name="KAFKA_CFG_MESSAGE_MAX_BYTES"
                        value=26214400 #25MB
                    }

                    env{
                        name="KAFKA_HEAP_OPTS"
                        value="-Xmx12g -Xms12g"
                    }

                    # env{
                    #     name="KAFKA_CFG_NUM_PARTITIONS"
                    #     value=1
                    # } This behaved wierdly


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
    depends_on = [kubernetes_deployment.kafka, kubernetes_stateful_set.elassandra]
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

                    resources {
                      requests = {
                        cpu = "14"
                        memory = "16G"
                      }
                    }

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
                    image = "docker.elastic.co/kibana/kibana-oss:6.8.4"
                    name="kibana"

                    resources {
                      requests= {
                        cpu="8"
                        memory="16G"
                      }
                    }

                    env{
                        name = "ELASTICSEARCH_HOSTS"
                        value = "http://elassandra:9200"
                    }

                    env{
                        name = "SERVER_HOST"
                        value = "0.0.0.0"
                    }

                    env{
                        # Need to set this to match ingress configuration below
                        name="SERVER_BASEPATH"
                        value = "/nims/kibana"
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
# Used this for reference https://github.com/strapdata/kubernetes-elassandra/blob/master/elassandra-statefulset.yaml
resource "kubernetes_stateful_set" "elassandra"{
    depends_on = [ kubernetes_service.elassandra_service ]
    metadata{
        name = "elassandra"
        labels = {
            app = "elassandra"
        }
    }
    spec{
        replicas = 3
        service_name = kubernetes_service.elassandra_service.metadata.0.name
        
        update_strategy {
          type = "RollingUpdate"
        }


        selector{
            match_labels = {
                app = "elassandra"
            }
        }

        volume_claim_template {
          metadata {
            name="elassandra-volume-claim"
          }
          spec {
            access_modes = [ "ReadWriteMany" ]
            storage_class_name = "standard"
            resources {
              requests = {
                "storage" = var.elassandra_volume_size
              }
            }
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

                init_container {
                  name = "increase-vm-max-map-count"
                  image = "busybox"
                  image_pull_policy = "IfNotPresent"
                  command = [ "sysctl", "-w", "vm.max_map_count=1048575" ]
                  security_context {
                    privileged = true
                  }
                }

                init_container {
                  name = "increase-ulimit"
                  image = "busybox"
                  command = [ "sh", "-c", "ulimit -l unlimited" ]
                  security_context {
                    privileged = true
                  }
                }

                # Ensure no two pod instances are deployed on the same node
                affinity {
                  pod_anti_affinity{
                      required_during_scheduling_ignored_during_execution{   
                            label_selector {
                                match_expressions{
                                    key = "nims.cluster.segment"
                                    operator = "In"
                                    values = ["datastore"]
                                }
                            }
                          
                            topology_key = "kubernetes.io/hostname"
                      }
                  }
                }

                dns_policy = "ClusterFirstWithHostNet"
                #Elassandra container
                container{
                    image = "strapdata/elassandra:6.8.4"
                    name = "elassandra"

                    security_context {
                      privileged = false
                      capabilities {
                        add = [ "IPC_LOCK", "SYS_RESOURCE" ]
                      }
                    }

                    #Elassandra Environment variables
                    #http://doc.elassandra.io/en/latest/installation.html#environment-variables
                    env{
                        name = "CASSANDRA_LISTEN_ADDRESS"
                        value_from {
                          field_ref {
                            field_path = "status.podIP"
                          }
                        }
                    }

                    env{
                        name="CASSANDRA_CLUSTER_NAME"
                        value = "Elassandra-Looking-Glass"
                    }

                    env {
                      name="CASSANDRA_SERVICE"
                      value="elassandra"
                    }

                    env{
                        name="CASSANDRA_SEEDS"
                        value="elassandra-0.elassandra.default.svc.cluster.local"
                    }

                    env{
                        #Data Center Name
                        name="CASSANDRA_DC"
                        value="nims-cluster"
                    }

                    env{
                        #Rack Name should be deployed node name
                        name="CASSANDRA_RACK"
                        value_from {
                          field_ref {
                            field_path = "spec.nodeName"
                          }
                        }
                    }

                    env{
                        name="NAMESPACE"
                        value_from {
                          field_ref {
                            field_path = "metadata.namespace"
                          }
                        }
                    }

                    env{
                        name="POD_NAME"
                        value_from {
                          field_ref{
                              field_path = "metadata.name"
                          }
                        }
                    }

                    env{
                        name="POD_IP"
                        value_from {
                          field_ref {
                            field_path = "status.podIP"
                          }
                        }
                    }

                    env{
                        name="MAX_HEAP_SIZE"
                        value = "8192M"
                    }

                    # Should be 1/4 MAX_HEAP_SIZE
                    # https://docs.wso2.com/display/MB211/Cassandra+Tuning
                    env{
                        name="HEAP_NEWSIZE"
                        value = "2048M"
                    }

                    # Logging 
                    env{
                        name="LOGBACK_org_elassandra_discovery"
                        value = "DEBUG"
                    }

                    env{
                        name="http.cors.enabled"
                        value="true"
                    }

                    env{
                        name="http.cors.allow-origin"
                        value="/http?:\\/\\/localhost(:[0-9]+)?/"
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

                    # Ensure elassandra nodes are drained when stopped
                    lifecycle {
                      pre_stop {
                        exec {
                          command = [ "/bin/sh", "-c", "nodetool drain" ]
                        }
                      }
                    }

                    resources {
                      requests = {
                        cpu = "8" # 8-cores 
                        memory = "16G" #16GB of RAM
                      }
                    }

                    volume_mount{
                        name = "elassandra-volume-claim"
                        mount_path = "/var/lib/cassandra"
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
                    
                    resources {
                      requests = {
                        cpu = "6"
                        memory = "8G"
                      }
                    }

                    env{
                        name = "SCHEMA_REGISTRY_HOST_NAME"
                        value = "localhost"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL"
                        value = "zoo1:2181"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_KAFKASTORE_TOPIC_REPLICATION_FACTOR"
                        value = "1"
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

                    resources {
                      requests = {
                        cpu = "6"
                        memory = "8G"
                      }
                    }

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
        }

        selector = {
                app = "zookeeper"
        }

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
        # Port 9092 is meant for clients, if you're looking to send messages
        # to kafka this is where you do it.
        port{
            name = "kafka"
            port = 9092
            # node_port = 30701

        }

        # Port 9093 is meant for other kafka brokers working together, this is like
        # the internal broker port.
        port{
            name = "kafka2"
            port = 9093

        }
        
        selector = {
            app = "kafka"
        }
        
        # type = "NodePort"
        # external_traffic_policy = "Local"

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
        }

        selector = {
            app = "avro-registry"
        }

    }
}

#Elassandra Service
resource "kubernetes_service" "elassandra_service" {
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
        }

        # Elastic Search HTTP
        port{
            name = "elastic-http"
            port = 9200
        }

        # Thrift Service
        port{
            name = "thrift-service"
            port = 9160
        }

        # Encrypted CQL
        port{
            name = "encrypted-cql"
            port = 9142
        }

        # CQL
        port{
            name = "cql"
            port = 9042
        }

        # JMX
        port{
            name = "jmx"
            port = 7199
        }

        # TLS intra-node communication
        port{
            name = "intra-tls"
            port = 7001
        }

        # Intra-node communication
        port{
            name = "intra"
            port = 7000

        }

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
        }

        selector = {
            app = "connect"
        }
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

# Ingress Configuration
resource "kubernetes_ingress" "looking_glass_ingress"{
    metadata {
      name = "looking-glass-ingress"
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
        "nginx.org/rewrites" = "serviceName=${kubernetes_service.kibana_service.metadata.0.name} rewrite=/;serviceName=${kubernetes_service.kafka_service.metadata.0.name} rewrite=/;serviceName=${kubernetes_service.elassandra_service.metadata.0.name} rewrite=/;serviceName=${kubernetes_service.avro_registry.metadata.0.name} rewrite=/;serviceName=${kubernetes_service.kafka_connect_service.metadata.0.name} rewrite=/"
        "nginx.org/mergeable-ingress-type" = "minion"
        # This doesn't work for some reason :( no auth for us I guess
        # "nginx.ingress.kubernetes.io/auth-type" = "basic"
        # "nginx.ingress.kubernetes.io/auth-secret" = "basic-auth"
        # "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required"
      }
    }

    spec {
      rule {
          host = "os-vm230.research.cs.dal.ca"
        http{
            
            # Kibana
            path{
                path = "/nims/kibana/"

                backend{
                    service_name = kubernetes_service.kibana_service.metadata.0.name
                    service_port = 5601
                }
            }

            # Add path for elastic search once we need it available externally
            path{
                path = "/nims/es/"

                backend {
                  service_name = kubernetes_service.elassandra_service.metadata.0.name
                  service_port = 9200
                }
            }

            #Add path for Avro Registry
            path{
                path = "/nims/avro-registry/"

                backend {
                  service_name = kubernetes_service.avro_registry.metadata.0.name
                  service_port = 9081
                }
            }

            # Add path for Kafka Connect once we have API support for it in the integrationn libraries
            path{
                path = "/nims/kafka-connect/"

                backend {
                  service_name = kubernetes_service.kafka_connect_service.metadata.0.name
                  service_port = 8082
                }
            }
        }
      }

    }
}

# Create persistent volumes in each node specified in the elassandra_data_nodes list
resource "kubernetes_persistent_volume" "elassandra_volume"{
    for_each = var.elassandra_data_nodes
    metadata{
        name = "elassandra-pv-${each.key}"
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
                        values = [each.value]
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



