pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('dockerhub-credentials')
        IMAGE_NAME = "${DOCKERHUB_CREDS_USR}/url-shortener"
        IMAGE_TAG = "${GIT_COMMIT}"
        KUBE_NAMESPACE_APP = "app"
        KUBE_NAMESPACE_JENKINS = "jenkins"
        EKS_CLUSTER_NAME = "ci-cd-eks"
        AWS_REGION = "us-west-2"
        DOCKER_HOST = "tcp://localhost:2375"
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

        stage('Create DockerHub Secret in Kubernetes') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                      usernameVariable: 'USER',
                                                      passwordVariable: 'PASS')]) {
                        sh """
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}

                            # Create namespace if missing
                            kubectl create namespace ${KUBE_NAMESPACE_JENKINS} --dry-run=client -o yaml | kubectl apply -f -

                            # Create DockerHub secret
                            kubectl create secret docker-registry regcred \
                                --docker-server=docker.io \
                                --docker-username=$USER \
                                --docker-password=$PASS \
                                --namespace ${KUBE_NAMESPACE_JENKINS} \
                                --dry-run=client -o yaml | kubectl apply -f -
                        """
                    }
                }
            }
        }

        stage('Deploy Jenkins & App to EKS') {
            steps {
                script {
                    // Jenkins deployment
                    sh """
                        kubectl apply -f k8s/jenkins_ns.yaml
                        kubectl apply -f k8s/rbac.yaml -n ${KUBE_NAMESPACE_JENKINS}
                        kubectl apply -f k8s/pvc.yaml -n ${KUBE_NAMESPACE_JENKINS}
                        kubectl apply -f k8s/jenkins_deployment.yaml -n ${KUBE_NAMESPACE_JENKINS}
                        kubectl apply -f k8s/jenkins_service.yaml -n ${KUBE_NAMESPACE_JENKINS}
                        kubectl rollout status deployment/jenkins -n ${KUBE_NAMESPACE_JENKINS}

                        # App deployment
                        kubectl apply -f k8s/app_ns.yaml
                        kubectl apply -f k8s/app_deployments.yaml -n ${KUBE_NAMESPACE_APP}
                        kubectl apply -f k8s/app_service.yaml -n ${KUBE_NAMESPACE_APP}
                        kubectl rollout status deployment/myapp -n ${KUBE_NAMESPACE_APP}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
            sh "kubectl get all -n ${KUBE_NAMESPACE_APP}"
            sh "kubectl get all -n ${KUBE_NAMESPACE_JENKINS}"
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
