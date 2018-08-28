/* PROVIDERS --------------------------------------*/

provider "digitalocean" {
  token = "${var.digitalocean_token}"
}
provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}
provider "google" {
  credentials = "${file("google-cloud.json")}"
  project     = "russia-servers"
  region      = "us-central1"
}
provider "alicloud" {
  access_key = "${var.alicloud_access_key}"
  secret_key = "${var.alicloud_secret_key}"
  region     = "${var.alicloud_region}"
}

/* BACKEND ----------------------------------------*/

terraform {
  backend "consul" {
    address   = "https://consul.statusim.net:8400"
    lock      = true
    /* WARNING This needs to be changed for every repo. */
    path      = "terraform/swarm/"
    ca_file   = "ansible/files/consul-ca.crt"
    cert_file = "ansible/files/consul-client.crt"
    key_file  = "ansible/files/consul-client.key"
  }
}

/* WORKSPACES -----------------------------------*/

locals {
  ws = "${merge(local.env["defaults"], local.env[terraform.workspace])}"
}

/* RESOURCES --------------------------------------*/

module "swarm" {
  source      = "modules/multi-provider"
  /* node type */
  name        = "node"
  group       = "swarm"
  /* scaling options */
  count       = "${local.ws["hosts_count"]}"
  do_size     = "s-1vcpu-2gb"
  /* general */
  env         = "${var.env}"
  domain      = "${var.domain}"
  eth_network = "${var.eth_network}"
  /* firewall */
  open_ports  = [
    "8800-8800", /* http */
    "30303-30303", /* geth */
    "30399-30399", /* swarm */
  ]
}
