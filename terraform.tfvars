region                = "us-west-2"
cluster_name          = "ci-cd-eks"
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
node_group_instance_type = "t3.small"
jenkins_ng_desired    = 1
app_ng_desired        = 1
