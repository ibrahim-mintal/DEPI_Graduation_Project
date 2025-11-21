# DEPI Graduation Project: URL Shortener on AWS EKS

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-LTS-D24939)](https://www.jenkins.io/)

A comprehensive URL shortener application built with Flask, containerized with Docker, and deployed on AWS EKS using Infrastructure as Code (Terraform), Kubernetes orchestration, and Jenkins CI/CD pipelines.

## Table of Contents
- [Project Description](#project-description)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
  - [1. Provision AWS EKS Cluster](#1-provision-aws-eks-cluster)
  - [2. Configure Kubernetes Access](#2-configure-kubernetes-access)
  - [3. Deploy Kubernetes Manifests](#3-deploy-kubernetes-manifests)
- [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Contributing](#contributing)
- [License](#license)

## Project Description

This project demonstrates a full-stack DevOps implementation of a URL shortener service. The application is a simple Flask-based API that allows users to shorten long URLs into short codes, store them in an SQLite database, and redirect to the original URLs. The infrastructure is provisioned using Terraform, deployed on Kubernetes (EKS), and automated via Jenkins pipelines.

Key features:
- URL shortening and redirection
- SQLite database for persistence
- Containerized with Docker
- Scalable deployment on AWS EKS
- CI/CD with Jenkins
- Persistent storage for Jenkins

## Architecture Overview

The architecture consists of the following components:

- **AWS Infrastructure**: VPC, subnets, security groups, EKS cluster with dedicated node groups for Jenkins and the application.
- **Kubernetes**: Namespaces for `app` and `jenkins`, deployments, services, persistent volume claims, and RBAC for Jenkins.
- **Application**: Flask app running in a Docker container, exposed via a LoadBalancer service.
- **CI/CD**: Jenkins pipeline that builds Docker images, pushes to ECR, and deploys to EKS.
- **Storage**: EBS-backed persistent volumes for Jenkins home directory.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │ -> │     Jenkins     │ -> │     AWS EKS     │
│                 │    │   (CI/CD)       │    │   (Deployment)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   URL Shortener │
                    │    (Flask App)  │
                    └─────────────────┘
```

## Prerequisites

Before setting up the project, ensure you have the following:

- **AWS Account**: With permissions to create EKS clusters, EC2 instances, VPCs, IAM roles, and ECR repositories.
- **Tools**:
  - Terraform (>= 1.0)
  - kubectl (configured for EKS)
  - AWS CLI (configured with your credentials)
  - Docker
  - Git
- **Knowledge**: Basic understanding of AWS, Kubernetes, and CI/CD pipelines.
- **Resources**: Sufficient AWS limits for EKS, EC2, and EBS.

## Step-by-Step Setup Guide

### 1. Provision AWS EKS Cluster

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/ibrahim-atef/DEPI_Graduation_Project.git
   cd DEPI_Graduation_Project
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review and Customize Variables**:
   - Edit `terraform.tfvars` to set your desired values (e.g., region, cluster name).
   - Check `variables.tf` for available options.

4. **Plan the Deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the Infrastructure**:
   ```bash
   terraform apply
   ```
   This will create:
   - VPC with public subnets
   - EKS cluster with two node groups (jenkins-ng and app-ng)
   - IAM roles and policies
   - Security groups

6. **Verify Cluster Creation**:
   ```bash
   aws eks describe-cluster --name ci-cd-eks --region us-west-2
   ```

### 2. Configure Kubernetes Access

1. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name ci-cd-eks
   ```

2. **Verify Access**:
   ```bash
   kubectl get nodes
   kubectl get namespaces
   ```

### 3. Deploy Kubernetes Manifests

1. **Apply Namespaces**:
   ```bash
   kubectl apply -f k8s/app_ns.yaml
   kubectl apply -f k8s/jenkins_ns.yaml
   ```

2. **Deploy RBAC for Jenkins**:
   ```bash
   kubectl apply -f k8s/rbac.yaml
   ```

3. **Create Persistent Volume Claim for Jenkins**:
   ```bash
   kubectl apply -f k8s/pvc.yaml
   ```

4. **Deploy Jenkins**:
   ```bash
   kubectl apply -f k8s/jenkins_deployment.yaml
   kubectl apply -f k8s/jenkins_service.yaml
   ```

5. **Deploy the Application**:
   ```bash
   kubectl apply -f k8s/app_deployment.yaml
   kubectl apply -f k8s/app_service.yaml
   ```

6. **Verify Deployments**:
   ```bash
   kubectl get pods -n app
   kubectl get pods -n jenkins
   kubectl get services -n jenkins
   kubectl get services -n app
   ```

7. **Get Jenkins Admin Password** (if needed):
   Run the `jenkins-password.sh` script or manually retrieve from the pod:
   ```bash
   kubectl exec -n jenkins -it $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```

## Jenkins Pipeline Configuration

The Jenkins pipeline is defined in `Jenkinsfile` and includes the following stages:

1. **Checkout**: Pulls the latest code from the GitHub repository.
2. **Build Docker Image**: Builds the Docker image for the Flask app.
3. **Push to DockerHub**: Tags and pushes the image to DockerHub.
4. **Deploy to EKS**: Updates the Kubernetes deployment with the new image and waits for rollout.

To set up the pipeline:

1. Access Jenkins UI (via LoadBalancer service).
2. Create a new pipeline job.
3. Configure it to use the `Jenkinsfile` from the repository.
4. Ensure AWS credentials are configured in Jenkins for ECR and EKS access.

## Usage

Once deployed, access the application via the LoadBalancer URL (check `kubectl get services -n app`).

### API Endpoints

- `GET /`: Serves a simple HTML interface or API info.
- `GET /health`: Health check endpoint.
- `POST /shorten`: Shorten a URL. Body: `{"url": "https://example.com"}`.
- `GET /<short_code>`: Redirect to the original URL.
- `GET /stats`: Get statistics (total shortened URLs).
- `GET /list`: List recent shortened URLs.

Example usage with curl:
```bash
curl -X POST http://<loadbalancer-url>/shorten -H "Content-Type: application/json" -d '{"url": "https://www.google.com"}'
```# Pipeline test Fri Nov 21 04:27:02 EET 2025
