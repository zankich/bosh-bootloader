output "cfcr_master_target_pool" {
  value = "${google_compute_target_pool.cfcr-tcp-public.name}"
}

output "service_account_master" {
  value = "${google_service_account.master.email}"
}

output "service_account_worker" {
  value = "${google_service_account.worker.email}"
}

output "master_lb_ip_address" {
  value = "${google_compute_address.cfcr-tcp.address}"
}

output "project_id" {
  value = "${var.project_id}"
}
