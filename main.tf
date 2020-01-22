/* PROVIDERS --------------------------------------*/

provider "digitalocean" {
  token = var.digitalocean_token
}

provider "cloudflare" {
  email      = var.cloudflare_email
  api_key    = var.cloudflare_token
  account_id = var.cloudflare_account
}

provider "google" {
  credentials = file("google-cloud.json")
  project     = "russia-servers"
  region      = "us-central1"
}

provider "alicloud" {
  access_key = var.alicloud_access_key
  secret_key = var.alicloud_secret_key
  region     = var.alicloud_region
}

/* BACKEND ----------------------------------------*/

terraform {
  backend "consul" {
    address = "https://consul.statusim.net:8400"
    lock    = true

    /* WARNING This needs to be changed for every repo. */
    path      = "terraform/swarm/"
    ca_file   = "ansible/files/consul-ca.crt"
    cert_file = "ansible/files/consul-client.crt"
    key_file  = "ansible/files/consul-client.key"
  }
}

/* WORKSPACES -----------------------------------*/

locals {
  ws = merge(local.env["defaults"], local.env[terraform.workspace])
}

/* CF Zones ------------------------------------*/

/* CloudFlare Zone IDs required for records */
data "cloudflare_zones" "active" {
  filter { status = "active" }
}

/* For easier access to zone ID by domain name */
locals {
  zones = {
    for zone in data.cloudflare_zones.active.zones:
      zone.name => zone.id
  }
}

/* RESOURCES --------------------------------------*/

module "swarm" {
  source = "github.com/status-im/infra-tf-multi-provider"

  /* node type */
  name  = "node"
  group = "swarm"

  /* scaling options */
  host_count  = local.ws["hosts_count"]
  do_size     = "s-2vcpu-4gb"
  gc_size     = "n1-standard-2"
  ac_size     = "ecs.sn1ne.large"
  gc_vol_size = 50

  /* general */
  env    = var.env
  domain = var.domain

  /* firewall */
  open_ports = [
    "443",   /* https */
    "30303", /* geth */
    "30399", /* swarm */
  ]
}

resource "cloudflare_load_balancer_monitor" "main" {
  description    = "Root health check"
  expected_codes = "2xx"
  expected_body  = ""
  method         = "GET"
  type           = "https"
  path           = "/"
  interval       = 60
  retries        = 5
  timeout        = 7

  /* disables SSl cert check, this way we can use origin */
  allow_insecure = true
}

/* WARNING: Statically done until Terraform 0.12 arrives */
resource "cloudflare_load_balancer_pool" "main" {
  name               = "${terraform.workspace}-${var.env}"
  monitor            = cloudflare_load_balancer_monitor.main.id
  notification_email = "jakub@status.im"
  minimum_origins    = 1
  origins {
    name    = element(keys(module.swarm.hosts_by_dc["do-eu-amsterdam3"]), 0)
    address = element(values(module.swarm.hosts_by_dc["do-eu-amsterdam3"]), 0)
    enabled = true
  }
  origins {
    name    = element(keys(module.swarm.hosts_by_dc["gc-us-central1-a"]), 0)
    address = element(values(module.swarm.hosts_by_dc["gc-us-central1-a"]), 0)
    enabled = true
  }
  origins {
    name    = element(keys(module.swarm.hosts_by_dc["ac-cn-hongkong-c"]), 0)
    address = element(values(module.swarm.hosts_by_dc["ac-cn-hongkong-c"]), 0)
    enabled = true
  }
}

// This might work, not sure yet
resource "cloudflare_load_balancer" "main" {
  zone_id     = local.zones["status.im"]
  name        = "${terraform.workspace}-${var.env}.status.im"
  description = "Load balancing of Swarm fleet."
  proxied     = true

  fallback_pool_id = cloudflare_load_balancer_pool.main.id
  default_pool_ids = [cloudflare_load_balancer_pool.main.id]
}
