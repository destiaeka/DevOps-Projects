data "aws_iam_role" "labrole" {
  name = "LabRole"
}

resource "aws_eks_cluster" "devops_project" {
  name = "devops_project"
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids = [
        aws_subnet.pub_a.id,
        aws_subnet.pub_b.id
    ]
    security_group_ids = [
        aws_security_group.sg_global.id
    ]
  }

  tags = {
    Name = "devops_project"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "coredns"
}

resource "aws_eks_addon" "vpccni" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "vpc-cni"
}

resource "aws_eks_addon" "kuberpoxy" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "kube-proxy"
}

resource "aws_eks_addon" "podidentityagent" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "externaldns" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "external-dns"
}

resource "aws_eks_addon" "metricsserver" {
  cluster_name      = aws_eks_cluster.devops_project.name
  addon_name        = "metrics-server"
}

resource "aws_eks_node_group" "devops_project_node" {
  cluster_name    = aws_eks_cluster.devops_project.name
  node_group_name = "devops_project"
  instance_types  = ["t3.medium"]
  node_role_arn   = data.aws_iam_role.labrole.arn
  subnet_ids      = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  tags = {
    Name = "devops_project"
  }
}