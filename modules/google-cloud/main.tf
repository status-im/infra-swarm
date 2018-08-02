/* DERIVED --------------------------------------*/
locals {
  stage      = "${terraform.workspace}"
  dc         = "${var.provider}-${var.zone}"
  /* always add SSH, Tinc, and Netdata to allowed ports */
  open_ports = ["22", "655", "8000", "${var.open_ports}"]
}
/* RESOURCES ------------------------------------*/

locals = {
  tags = [
    "${var.name}", "${local.stage}", "${var.env}",
    /* for precise targeting with firewall rules */
    "${var.name}-${var.env}-${local.stage}",
  ]
  tags_sorted = "${sort(distinct(local.tags))}"
}

resource "google_compute_address" "host" {
  name       = "${var.name}-${format("%02d", count.index+1)}-${local.dc}-${var.env}-${local.stage}"
  count      = "${var.count}"
  /*lifecycle  = { prevent_destroy = true }*/
}

resource "google_compute_firewall" "host" {
  name    = "allow-${var.name}-${var.zone}-${var.env}-${local.stage}"
  network = "default"
  target_tags = ["${var.name}-${var.env}-${local.stage}"]

  allow {
    protocol = "tcp"
    ports    = ["${local.open_ports}"]
  }
  allow {
    protocol = "udp"
    ports    = ["${local.open_ports}"]
  }
}

resource "google_compute_instance" "host" {
  name  = "${var.name}-${format("%02d", count.index+1)}-${local.dc}-${var.env}-${local.stage}"
  zone  = "${var.zone}"
  count = "${var.count}"

  machine_type = "${var.machine_type}"
  /* enable changing machine_type */
  allow_stopping_for_update = true

  tags = ["${local.tags_sorted}"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${element(google_compute_address.host.*.address, count.index)}"
    }
  }

  metadata {
    node     = "${var.name}"
    env      = "${var.env}"
    group    = "${var.group}"
    /* This is a hack because we can't use dots in actual instance name */
    hostname = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"
    /* Enable SSH access */
    sshKeys  = "${var.ssh_user}:${file(var.ssh_key)}"
  }

  /* bootstrap access to host and basic resources */
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

resource "cloudflare_record" "host" {
  domain = "${var.domain}"
  count  = "${var.count}"
  name   = "${element(google_compute_instance.host.*.metadata.hostname, count.index)}"
  value  = "${element(google_compute_instance.host.*.network_interface.0.access_config.0.assigned_nat_ip , count.index)}"
  type   = "A"
  ttl    = 3600
}

resource "ansible_host" "host" {
  inventory_hostname = "${element(google_compute_instance.host.*.metadata.hostname, count.index)}"
  groups = ["${var.group}", "${local.dc}"]
  count = "${var.count}"
  vars {
    ansible_user   = "admin"
    ansible_host   = "${element(google_compute_instance.host.*.network_interface.0.access_config.0.assigned_nat_ip , count.index)}"
    hostname       = "${element(google_compute_instance.host.*.metadata.hostname, count.index)}"
    region         = "${element(google_compute_instance.host.*.zone, count.index)}"
    dns_entry      = "${element(google_compute_instance.host.*.metadata.hostname, count.index)}.${var.domain}"
    nodes_per_host = "${var.nodes_per_host}"
    eth_network    = "${var.eth_network}"
    data_center    = "${local.dc}"
    stage          = "${local.stage}"
    env            = "${var.env}"
  }
}
