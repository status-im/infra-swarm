output "public_ip" {
  value = ["${digitalocean_floating_ip.host.*.ip_address}"]
}
