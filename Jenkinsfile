pipeline {
    agent any

    environment {
        // DockerHub credentials
        DOCKERHUB_CREDS = credentials('dockerhub-credentials')
        IMAGE_NAME = "${DOCKERHUB_CREDS_USR}/myapp"
        IMAGE_TAG = "${GIT_COMMIT}"          // Immutable tag using Git commit
        KUBE_NAMESPACE_APP = "app"           // App namespace
        KUBE_NAMESPACE_JENKINS = "jenkins"   // Jenkins namespace
        EKS_CLUSTER_NAME = "ci-cd-eks"
        AWS_REGION = "us-west-2"
    }


    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ./app
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    """

                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                      usernameVariable: 'USER',
                                                      passwordVariable: 'PASS')]) {
                        sh """
                            echo $PASS | docker login -u $USER --password-stdin
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy Jenkins & App to EKS') {
            steps {
                script {
                    // Configure kubectl for EKS
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"

                    // Jenkins deployment (first node)
                    sh "kubectl apply -f k8s/jenkins_ns.yaml"
                    sh "kubectl apply -f k8s/jenkins_deployment.yaml -n ${KUBE_NAMESPACE_JENKINS}"
                    sh "kubectl apply -f k8s/jenkins_service.yaml -n ${KUBE_NAMESPACE_JENKINS}"
                    sh "kubectl apply -f k8s/pvc.yaml -n ${KUBE_NAMESPACE_JENKINS}"
                    sh "kubectl apply -f k8s/rbac.yaml -n ${KUBE_NAMESPACE_JENKINS}"
                    sh "kubectl rollout status deployment/jenkins -n ${KUBE_NAMESPACE_JENKINS}"

                    // Application deployment (second node)
                    sh "kubectl apply -f k8s/app_ns.yaml"
                    sh "kubectl apply -f k8s/app_deployments.yaml -n ${KUBE_NAMESPACE_APP}"
                    sh "kubectl apply -f k8s/app_service.yaml -n ${KUBE_NAMESPACE_APP}"
                    sh "kubectl rollout status deployment/myapp -n ${KUBE_NAMESPACE_APP}"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
            sh "kubectl get all -n ${KUBE_NAMESPACE_APP}"
        }
        failure {
            echo "Pipeline failed!"
        }
        always {
            sh """
                docker logout || true
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest || true
            """
            cleanWs()
        }
    }
}
