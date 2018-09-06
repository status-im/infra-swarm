locals {
  hostnames  = "${digitalocean_droplet.host.*.name}"
  public_ips = "${digitalocean_floating_ip.host.*.ip_address}"
}

output "hostnames" {
  value = ["${local.hostnames}"]
}

output "public_ips" {
  value = ["${local.public_ips}"]
}

output "hosts" {
  value = "${zipmap(local.hostnames, local.public_ips)}"
}
