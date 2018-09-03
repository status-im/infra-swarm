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
  gc_size     = "n1-standard-1"
  /* general */
  env         = "${var.env}"
  domain      = "${var.domain}"
  eth_network = "${var.eth_network}"
  /* firewall */
  open_ports  = [
    "8080-8080",   /* http */
    "8443-8443",   /* https */
    "30303-30303", /* geth */
    "30399-30399", /* swarm */
  ]
}

resource "cloudflare_record" "swarm" {
  domain  = "${var.domain}"
  name    = "${var.env}-${terraform.workspace}"
  value   = "${element(module.swarm.public_ips, count.index)}"
  count   = 3
  type    = "A"
  ttl     = 3600
  proxied = true
}
