output "public_ips" {
  value = ["${digitalocean_floating_ip.host.*.ip_address}"]
}
