resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "jenkins_ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-jenkins-ng"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = var.jenkins_ng_desired
    max_size     = var.jenkins_ng_desired
    min_size     = var.jenkins_ng_desired
  }

  instance_types = [var.node_group_instance_type]
  capacity_type  = "ON_DEMAND"

  labels = {
    "node-role" = "jenkins-node"
  }

  tags = {
    Name = "${var.cluster_name}-jenkins-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.worker_node_AmazonEBSCSIDriverPolicy,
    aws_eks_cluster.eks,
  ]
}

resource "aws_eks_node_group" "app_ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-app-ng"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = var.app_ng_desired
    max_size     = var.app_ng_desired
    min_size     = var.app_ng_desired
  }

  instance_types = [var.node_group_instance_type]
  capacity_type  = "ON_DEMAND"

  labels = {
    "node-role" = "app-node"
  }

  tags = {
    Name = "${var.cluster_name}-app-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.worker_node_AmazonEBSCSIDriverPolicy,
    aws_eks_cluster.eks,
  ]
}
