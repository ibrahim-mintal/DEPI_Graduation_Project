# Get EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster_name
}

# Create OIDC provider for EKS cluster (only if it doesn't exist)
resource "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afdcd71e"]
}

# IAM policy document for EBS CSI IRSA role
data "aws_iam_policy_document" "ebs_csi_irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
        test     = "StringEquals"
        variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
        values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
        }
        }
        }

# EBS CSI IAM Role (IRSA)
resource "aws_iam_role" "ebs_csi_irsa_role" {
  name               = "ebs-csi-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa_assume_role.json
  tags = {
    "Purpose" = "EBS CSI IRSA"
  }
}

# Attach EBS CSI managed policy
resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role       = aws_iam_role.ebs_csi_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Kubernetes service account for EBS CSI driver
resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_irsa_role.arn
    }
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
}
