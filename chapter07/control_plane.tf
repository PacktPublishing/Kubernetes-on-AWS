/*
  Trust policy to allow EKS service to
  assume our IAM role
*/
data "aws_iam_policy_document" "control_plane" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

/*
  IAM role to be used by EKS to interact with
  our account.
*/
resource "aws_iam_role" "control_plane" {
  name = "EKSControlPlane"
  assume_role_policy = "${data.aws_iam_policy_document.control_plane.json}"
}

/*
  Attach the required policies to the EKS IAM role
*/
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.control_plane.name}"
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.control_plane.name}"
}

/*
  Security Group for EKS network interfaces
*/
resource "aws_security_group" "control_plane" {
  name        = "${var.cluster_name}-control-plane"
  description = "EKS Cluster ${var.cluster_name}"
  vpc_id      = "${aws_vpc.k8s.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}"
  }
}

/*
  Create the EKS cluster
*/
resource "aws_eks_cluster" "control_plane" {
  name            = "${var.cluster_name}"
  role_arn        = "${aws_iam_role.control_plane.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.control_plane.id}"]
    subnet_ids         = ["${concat(aws_subnet.public.*.id,aws_subnet.private.*.id)}"]
  }

  version = "${var.k8s_version}"

  depends_on = [
    "aws_iam_role_policy_attachment.eks_service",
    "aws_iam_role_policy_attachment.eks_cluster",
  ]
}
