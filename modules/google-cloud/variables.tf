/* SCALING ---------------------------------------*/

variable count {
  description = "Number of hosts to run."
}

variable nodes_per_host {
  description = "Number of statsd containers to run per host."
}

variable machine_type {
  description = "Type of machine to deploy."
  /* https://cloud.google.com/compute/docs/machine-types */
  default     = "n1-standard-1"
}

variable zone {
  description = "Specific zone in which to deploy hosts."
  /* https://cloud.google.com/compute/docs/regions-zones/ */
  default     = "us-central1-a"
}

variable image {
  description = "OS image to use when deploying hosts."
  /* https://cloud.google.com/compute/docs/images */
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable provider {
  description = "Short name of the provider used."
  /* Google Cloud */
  default     = "gc"
}

/* CONFIG ----------------------------------------*/

variable name {
  description = "Name for hosts. To be used in the DNS entry."
}

variable env {
  description = "Environment for these hosts, affects DNS entries."
}

variable group {
  description = "Ansible group to assign hosts to."
}

variable domain {
  description = "DNS Domain to update"
}

variable eth_network {
  description = "Ethereum network to connect to."
  default     = 1
}

/* MODULE ----------------------------------------*/

variable ssh_user {
  description = "User used to log in to instance"
  default     = "root"
}

variable ssh_key {
  description = "Names of ssh public keys to add to created hosts"
  /* TODO this needs to be dynamic */
  default     = "~/.ssh/status.im/id_rsa.pub"
}

/* FIREWALL -------------------------------------------*/

variable open_ports {
  description = "Port ranges to enable access from outside. Format: 'N-N'"
  type        = "list"
  default     = []
}
