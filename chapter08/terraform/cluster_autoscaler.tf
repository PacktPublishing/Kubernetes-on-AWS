data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_role.node.arn}"]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cluster-autoscaler" {
  name = "EKSClusterAutoscaler"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler"
  role = "${aws_iam_role.cluster_autoscaler.id}"
  policy = "${data.aws_iam_policy_document.cluster_autoscaler.json}"
}

data "aws_region" "current" {}

data "template_file" "cluster_autoscaler" {
  template = "${file("${path.module}/cluster_autoscaler.tpl")}"

  vars {
    aws_region = "${data.aws_region.current.name}"
    cluster_name = "${aws_eks_cluster.control_plane.name}"
    iam_role = "${aws_iam_role.cluster_autoscaler.name}"
  }
}

resource "null_resource" "cluster_autoscaler" {
  trigers = {
    manifest_sha1 = "${sha1("${data.template_file.cluster_autoscaler.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${local_file.kubeconfig.filename} apply -f -<<EOF\n${data.template_file.cluster_autoscaler.rendered}\nEOF"
  }
}
