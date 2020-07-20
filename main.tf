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
                        name = "KAFKA_LISTENERS"
                        value = "PLAINTEXT://:9092"
                    }

                    env{
                        name = "KAFKA_ADVERTISED_LISTENERS"
                        value = "PLAINTEXT://kafka:9092"
                    }

                    env{
                        name="KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE"
                        value="TRUE"
                    }

                    port{
                        container_port = 9092
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
                
                #Schema Registry container
                container{
                    image = "confluentinc/cp-schema-registry:5.5.1"
                    name = "avro-registry"

                     env{
                        name = "SCHEMA_REGISTRY_HOST_NAME"
                        value = "avro-registry"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL"
                        value = "zoo1:2181"
                    }

                    env{
                        name = "SCHEMA_REGISTRY_LISTENERS"
                        value = "http://localhost:9081"
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
        name = "avro-registry"
        labels = {
            app = "avro-registry"
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
