/* DERIVED --------------------------------------*/
locals {
  stage = "${terraform.workspace}"
  dc    = "${var.provider}-${var.region}"
}
/* RESOURCES ------------------------------------*/

# create a tag for every segment of workspace separate by dot
locals = {
  tags = ["${local.stage}", "${var.group}", "${var.env}"]
  tags_sorted = "${sort(distinct(local.tags))}"
  tags_count = "${length(local.tags_sorted)}"
}

resource "digitalocean_tag" "host" {
  name  = "${element(local.tags_sorted, count.index)}"
  count = "${local.tags_count}"
}

resource "digitalocean_droplet" "host" {
  image    = "${var.image}"
  name     = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"
  region   = "${var.region}"
  size     = "${var.size}"
  count    = "${var.count}"
  ssh_keys = "${var.ssh_keys}"
  tags     = ["${digitalocean_tag.host.*.id}"]

  provisioner "ansible" {
    plays {
      playbook = "${path.cwd}/ansible/bootstrap.yml"
      groups   = ["${var.group}"]
      extra_vars = {
        hostname         = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"
        ansible_ssh_user = "${var.ssh_user}"
        data_center      = "${local.dc}"
        stage            = "${local.stage}"
        env              = "${var.env}"
      }
    }
    local = "yes"
  }
}

resource "digitalocean_floating_ip" "host" {
  droplet_id = "${element(digitalocean_droplet.host.*.id, count.index)}"
  region     = "${element(digitalocean_droplet.host.*.region, count.index)}"
  count      = "${var.count}"
  /*lifecycle  = { prevent_destroy = true }*/
}

resource "cloudflare_record" "host" {
  domain = "${var.domain}"
  count  = "${var.count}"
  name   = "${element(digitalocean_droplet.host.*.name, count.index)}"
  value  = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
  type   = "A"
  ttl    = 3600
}

resource "ansible_host" "host" {
  inventory_hostname = "${element(digitalocean_droplet.host.*.name, count.index)}"
  groups = ["${var.group}", "${local.dc}"]
  count = "${var.count}"
  vars {
    ansible_user   = "admin"
    ansible_host   = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
    hostname       = "${element(digitalocean_droplet.host.*.name, count.index)}"
    region         = "${element(digitalocean_droplet.host.*.region, count.index)}"
    dns_entry      = "${element(digitalocean_droplet.host.*.name, count.index)}.${var.domain}"
    nodes_per_host = "${var.nodes_per_host}"
    eth_network    = "${var.eth_network}"
    data_center    = "${local.dc}"
    stage          = "${local.stage}"
    env            = "${var.env}"
  }
}
