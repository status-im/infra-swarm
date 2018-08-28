output "public_ips" {
  value = ["${google_compute_instance.host.*.network_interface.0.access_config.0.assigned_nat_ip }"]
}
