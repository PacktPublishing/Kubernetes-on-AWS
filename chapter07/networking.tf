/*
  Set up a VPC for our cluster.
*/
resource "aws_vpc" "k8s" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "${var.cluster_name}",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"
}

/*
  In order for our instances to connect to the internet
  we provision an internet gateway.
*/
resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.k8s.id}"

  tags {
    Name = "${var.cluster_name}"
  }
}

/*
  For instances without a Public IP address we will route traffic
  through a NAT Gateway. Setup an Elastic IP and attach it.

  We are only setting up a single NAT gateway, for simplicity.
  If the availability is important you might add another in a
  second availability zone.
*/
resource "aws_eip" "nat" {
  vpc        = true
  depends_on = ["aws_internet_gateway.gateway"]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.*.id[0]}"
}

/*
  Public network
  We create a /24 subnet for each AZ we are using.

  This gives us 251 usable IPs (per subnet) for resources we want
  to have public IP addresses like Load Balancers.
*/
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.k8s.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }

  tags {
    Name = "${var.cluster_name}-public"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.availability_zones)}"

  availability_zone       = "${var.availability_zones[count.index]}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr,8,count.index)}"
  vpc_id                  = "${aws_vpc.k8s.id}"
  map_public_ip_on_launch = true

  tags = "${
    map(
     "Name", "${var.cluster_name}-public-subnet",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"
}

resource "aws_route_table_association" "public" {
  count = "${length(var.availability_zones)}"

  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

/*
  Private network
  We create a /18 subnet for each AZ we are using.

  This gives us 16382 IPs (per subnet)

  We are using much larger subnet ranges for the private
  subnets as Pod IPs are allocated from these ranges,
  since Kubernetes  networking requires a Unique IP for each
  Pod we need lots of IPs.
*/



resource "aws_default_route_table" "private" {
  default_route_table_id = "${aws_vpc.k8s.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
  }

  tags {
    Name = "k8s-${var.cluster_name}-private"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(var.availability_zones)}"

  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr,2,count.index + 1)}"
  vpc_id            = "${aws_vpc.k8s.id}"

  tags = "${
    map(
     "Name", "${var.cluster_name}-private-subnet",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"
}

/*
  These associations are not strictly neccecary becuase the main route table
  is implictly associated with subnets without an accociation.
*/

resource "aws_route_table_association" "private" {
  count          = "${length(var.availability_zones)}"

  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_default_route_table.private.id}"
}
