locals {
  hostnames  = "${alicloud_instance.host.*.host_name}"
  public_ips = "${alicloud_eip.host.*.ip_address}"
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
