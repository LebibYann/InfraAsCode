variable "project_id" {
    type = string
    description = "Cloud project ID"
}

variable "region" { 
    type = string
    description = "Region for resources"

}

variable "db_name" { 
    type = string
    description = "Database name"
}

variable "db_user" { 
    type = string
    description = "Database user"
}

variable "node_count" { 
    type = number
    default = 2 
    description = "Number of nodes"
}

variable "machine_type" { 
    type = string
    default = "e2-medium"
    description = "Machine type"
}
