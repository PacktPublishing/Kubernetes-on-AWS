/*
  Template out a kubeconfig file for this cluster
*/
data "template_file" "kubeconfig" {
  template = "${file("${path.module}/kubeconfig.tpl")}"

  vars {
    cluster_name = "${var.cluster_name}"
    ca_data      = "${aws_eks_cluster.control_plane.certificate_authority.0.data}"
    endpoint     = "${aws_eks_cluster.control_plane.endpoint}"
  }
}

resource "local_file" "kubeconfig" {
  content = "${data.template_file.kubeconfig.rendered}"
  filename = "${path.module}/kubeconfig"
}
