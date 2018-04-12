output "kubernetes_cluster_tag" {
  value = "${random_id.kubernetes_cluster_tag.b64}"
}

output "cfcr_master_target_pool" {
  value = "${aws_elb.api.name}"
}

output "master_lb_ip_address" {
  value = "${aws_elb.api.dns_name}"
}

output "master_iam_instance_profile" {
  value = "${aws_iam_instance_profile.cfcr-master.name}"
}

output "worker_iam_instance_profile" {
  value = "${aws_iam_instance_profile.cfcr-worker.name}"
}
