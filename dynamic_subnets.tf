
data "aws_nat_gateway" "cluster_networking" {
  for_each = toset(var.nat_gateways)
  id       = each.key
}

data "aws_subnet" "cluster_networking" {
  for_each = { for i, nat in toset(var.nat_gateways) : i => nat }
  id       = data.aws_nat_gateway.cluster_networking[each.key].subnet_id
}

locals {
  nats_with_azs = {
    for i, nat in toset(var.nat_gateways) :
    replace(data.aws_subnet.cluster_networking[i].availability_zone, "-", "_") => nat
  }
  private_subnets_tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
  public_subnets_tags = merge(local.common_tags, {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
  # existing_subnets_nat_map = {
  #     for i,sn in toset(data.aws_subnet.existing_private_subnets): 
  #     sn.id => lookup(local.nats_with_azs,replace(sn.availability_zone, "-", "_"),var.nat_gateways[0])
  # }
}

data "aws_availability_zones" "available" {
  state = "available"
}



resource "aws_subnet" "cluster_public" {
  count             = length(var.vpc_public_subnets) > 0 ? length(var.vpc_public_subnets) : 0
  vpc_id            = var.vpc_id
  cidr_block        = var.vpc_public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = merge(local.public_subnets_tags, { Name = "${var.cluster_name}_public_${count.index}" })
}


resource "aws_subnet" "cluster_private" {
  count             = !var.use_existing_private_subnets && length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0
  vpc_id            = var.vpc_id
  cidr_block        = var.vpc_private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = merge(local.private_subnets_tags, { Name = "${var.cluster_name}_private_${count.index}" })
}



resource "aws_route_table" "cluster_private_rtb" {
  count  = !var.use_existing_private_subnets && length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = lookup(local.nats_with_azs, replace(data.aws_availability_zones.available.names[count.index], "-", "_"), var.nat_gateways[0])
  }
  tags = merge(local.common_tags, { Name = "${var.cluster_name}_private_rtb_${count.index}" })
}


resource "aws_route_table" "cluster_public_rtb_dynamic" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
  tags = merge(local.common_tags, { Name = "${var.cluster_name}_public_rtb" })
}

resource "aws_route_table_association" "cluster_public" {
  count          = length(var.vpc_public_subnets) > 0 ? length(var.vpc_public_subnets) : 0
  subnet_id      = aws_subnet.cluster_public[count.index].id
  route_table_id = aws_route_table.cluster_public_rtb_dynamic.id
}

resource "aws_route_table_association" "cluster_private" {
  count          = !var.use_existing_private_subnets && length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0
  subnet_id      = aws_subnet.cluster_private[count.index].id
  route_table_id = aws_route_table.cluster_private_rtb[count.index].id
}

data "aws_subnet" "existing_private_subnets" {
  count = var.use_existing_private_subnets && length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0
  filter {
    name   = "cidr-block"
    values = [var.vpc_private_subnets[count.index]]
  }
}
