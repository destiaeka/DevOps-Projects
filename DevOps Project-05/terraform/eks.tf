terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_iam_role" "labrole" {
  name = "Labrole"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name = "availability-zone"
    values = [
      "us-east-1a",
      "us-east-1b"
    ]
  }
}

resource "aws_eks_cluster" "my-cluster" {
  name = "my-cluster"
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  tags = {
    Name = "my-cluster"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "coredns"
}

resource "aws_eks_addon" "vpccni" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "vpc-cni"
}

resource "aws_eks_addon" "kuberpoxy" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "kube-proxy"
}

resource "aws_eks_addon" "podidentityagent" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "externaldns" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "external-dns"
}

resource "aws_eks_addon" "metricsserver" {
  cluster_name      = aws_eks_cluster.my-cluster.name
  addon_name        = "metrics-server"
}

resource "aws_eks_node_group" "node-mycluster" {
  cluster_name    = aws_eks_cluster.my-cluster.name
  node_group_name = "my-node"
  instance_types  = ["t3.medium"]
  node_role_arn   = data.aws_iam_role.labrole.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  tags = {
    Name = "my-node"
  }
  
  depends_on = [ aws_eks_cluster.my-cluster ]
}