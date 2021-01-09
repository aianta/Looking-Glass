variable CA {
    type = string
    default = ""
}
variable CLIENT_CERT {
    type = string
    default = ""
}
variable CLIENT_KEY {
    type = string
    default = ""
}
variable development {
    type = bool
    default = true
}

variable elassandra_volume_size{
    type = string
    default = "10Gi"
}

variable elassandra_data_path{
    type = string
}

variable elassandra_data_nodes{
    type = set(string)
}

