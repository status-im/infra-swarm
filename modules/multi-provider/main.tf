/**
 * Unfortunately Terraform does not support using the count parameter
 * with custom modules, for more details see:
 * https://github.com/hashicorp/terraform/issues/953
 *
 * Because of this to add a region/zone you have to copy a provider
 * module and give it a different region/size argument.
 */

/* Digital Ocean */

module "digital-ocean-ams3" {
  source         = "../digital-ocean"
  /* specific */
  name           = "${var.name}"
  count          = "${var.count}"
  env            = "${var.env}"
  group          = "${var.group}"
  eth_network    = "${var.eth_network}"
  /* scaling */
  size           = "${var.do_size}"
  nodes_per_host = "${var.nodes_per_host}"
  region         = "ams3"
  /* general */
  domain         = "${var.domain}"
}

resource "cloudflare_record" "do-ams3" {
  domain = "${var.domain}"
  name   = "nodes.do-ams3.${var.env}.${terraform.workspace}"
  value  = "${element(module.digital-ocean-ams3.public_ip, count.index)}"
  count  = "${var.count}"
  type   = "A"
  ttl    = 3600
}

/* Google Cloud */

module "google-cloud-us-central1" {
  source         = "../google-cloud"
  /* specific */
  name           = "${var.name}"
  count          = "${var.count}"
  env            = "${var.env}"
  group          = "${var.group}"
  eth_network    = "${var.eth_network}"
  /* scaling */
  machine_type   = "${var.gc_size}"
  nodes_per_host = "${var.nodes_per_host}"
  zone           = "us-central1-a"
  /* general */
  domain         = "${var.domain}"
  /* firewall */
  open_ports    = "${var.open_ports}"
}

resource "cloudflare_record" "gc-us-central1" {
  domain = "${var.domain}"
  name   = "nodes.gc-us-central1-a.${var.env}.${terraform.workspace}"
  value  = "${element(module.google-cloud-us-central1.public_ip, count.index)}"
  count  = "${var.count}"
  type   = "A"
  ttl    = 3600
}
