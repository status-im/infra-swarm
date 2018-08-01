variable count {
  description = "Number of hosts to run."
}

variable name {
  description = "Environment for these hosts, affects DNS entries."
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

variable nodes_per_host {
  description = "Number of statsd containers to run per host."
  default     = 0
}

/* Scaling -------------------------------------------*/

variable do_size {
  description = "Size of host to provision in Digital Ocean."
  default     = "s-1vcpu-1gb"
}

variable gc_size {
  description = "Size of host to provision in Google Cloud."
  default     = "n1-standard-1"
}

variable ac_size {
  description = "Size of host to provision in Google Cloud."
  default     = "ecs.t5-lc1m1.small"
}

/* Firewall -------------------------------------------*/

variable open_ports {
  description = "Port ranges to enable access from outside. Format: 'N-N'"
  type        = "list"
  default     = []
}
