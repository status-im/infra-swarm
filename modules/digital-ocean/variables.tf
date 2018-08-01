/* SCALING ---------------------------------------*/

variable count {
  description = "Number of hosts to run."
}

variable nodes_per_host {
  description = "Number of statsd containers to run per host."
}

variable size {
  description = "Size of the hosts to deploy."
  # cmd: doctl compute size list
  default     = "s-1vcpu-1gb"
}

variable region {
  description = "Region in which to deploy hosts."
  # cmd: doctl compute region list
  default     = "ams3"
}

variable image {
  description = "OS image to use when deploying hosts."
  # cmd: doctl compute image list --public
  default     = "ubuntu-18-04-x64"
}

variable provider {
  description = "Short name of the provider used."
  # DigitalOcean
  default     = "do"
}

/* GENERAL ---------------------------------------*/

variable name {
  description = "Name for hosts. To be used in the DNS entry."
}

variable group {
  description = "Ansible group to assign hosts to."
}

variable env {
  description = "Environment for these hosts, affects DNS entries."
}

variable domain {
  description = "DNS Domain to update"
}

variable eth_network {
  description = "Ethereum network to connect to."
}

variable ssh_user {
  description = "User used to log in to instance"
  default     = "root"
}

variable ssh_keys {
  description = "Names of ssh public keys to add to created hosts"
  type        = "list"
  # cmd: doctl compute ssh-key list
  default     = ["16822693", "18813432", "18813461", "19525749", "20671731", "20686611"]
}
