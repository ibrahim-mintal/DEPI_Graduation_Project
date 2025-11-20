resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_vpc.vpc,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

# Jenkins Node Group — only in first subnet (AZ1)
resource "aws_eks_node_group" "jenkins_ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-jenkins-ng"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = [aws_subnet.public[0].id]   # pick AZ1

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = [var.node_group_instance_type]
  capacity_type  = "ON_DEMAND"

  labels = { "node-role" = "jenkins-node" }

  tags = { Name = "${var.cluster_name}-jenkins-ng" }

  depends_on = [
    aws_eks_cluster.eks
  ]
}

# App Node Group — only in second subnet (AZ2)
resource "aws_eks_node_group" "app_ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-app-ng"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = [aws_subnet.public[1].id]   # pick AZ2

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = [var.node_group_instance_type]
  capacity_type  = "ON_DEMAND"

  labels = { "node-role" = "app-node" }

  tags = { Name = "${var.cluster_name}-app-ng" }

  depends_on = [
    aws_eks_cluster.eks
  ]
}
