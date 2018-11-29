/*
  IAM policy for nodes
*/

data "aws_iam_policy_document" "kube2iam" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "node" {
  name   = "kube2iam"
  role   = "${aws_iam_role.node.id}"
  policy = "${data.aws_iam_policy_document.kube2iam.json}"
}

data "aws_iam_policy_document" "node" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "EKSNode"
  assume_role_policy = "${data.aws_iam_policy_document.node.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.node.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.node.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.node.name}"
}

resource "aws_iam_instance_profile" "node" {
  name = "${aws_iam_role.node.name}"
  role = "${aws_iam_role.node.name}"
}

/*
  This config map configures which IAM roles should be trusted by Kubernetes

  Here we configure the IAM role assigned to the nodes to be in the
  system:bootstrappers and system:nodes groups so that the nodes
  may register themselves with the cluster and begin working.
*/

resource "local_file" "aws_auth" {
  content = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
YAML
  filename = "${path.module}/aws-auth-cm.yaml"
  depends_on = ["local_file.kubeconfig"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${local_file.kubeconfig.filename} apply -f ${path.module}/aws-auth-cm.yaml"
  }
}

/*
  Security Group for nodes
  This security group controls access to the Kubernetes worker nodes.
*/

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.k8s.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.cluster_name}-nodes",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "nodes-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.nodes.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "control_plane-ingress-nodes" {
  description              = "Allow kubelet to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.control_plane.id}"
  source_security_group_id = "${aws_security_group.nodes.id}"
  to_port                  = 443
  type                     = "ingress"
}

/*
  Allows control plane access to the Kubelet API. Used for exec and log streaming, etc.
*/
resource "aws_security_group_rule" "node-kubelet-ingress-control_plane" {
  description              = "Allow worker Kubelets to receive communication from the cluster control plane"
  from_port                = 10250
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.control_plane.id}"
  to_port                  = 10250
  type                     = "ingress"
}

/*
  This rule allows traffic to be proxied to pods/services running in the cluster via the API.
  It may be ommited if this is not required, but does break some confomance tests.
*/
resource "aws_security_group_rule" "nodes-ingress-control_plane" {
  description              = "Allow pods to receive communication from the cluster control plane"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.control_plane.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "bastion-ingress-nodes-ssh" {
  description              = "Allow bastion to ssh to nodes"
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.ssh_bastion.id}"
  to_port                  = 22
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["eks-worker-${var.k8s_version}*"]
  }

  most_recent = true
  owners      = ["self"]
}

resource "aws_launch_configuration" "node" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "c5.large"
  name_prefix                 = "eks-node-${var.cluster_name}"
  security_groups             = ["${aws_security_group.nodes.id}"]
  key_name                    = "${var.key_name}"

  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node" {
  launch_configuration = "${aws_launch_configuration.node.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-node-${var.cluster_name}"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-node-${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "enabled"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}
