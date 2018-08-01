output "public_ips" {
  value = ["${alicloud_eip.host.*.ip_address}"]
}

output "hostnames" {
  value = ["${alicloud_instance.host.*.host_name}"]
}
