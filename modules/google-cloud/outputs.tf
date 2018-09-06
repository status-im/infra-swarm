locals {
  hostnames  = "${google_compute_instance.host.*.metadata.hostname}"
  public_ips = "${google_compute_instance.host.*.network_interface.0.access_config.0.assigned_nat_ip }"
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
