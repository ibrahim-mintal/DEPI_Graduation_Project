pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins-sa
  nodeSelector:
    node-role: jenkins-node
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    imagePullPolicy: Always
    command:
    - cat
    tty: true
  - name: kubectl
    image: bitnami/kubectl:latest
    imagePullPolicy: Always
    command:
    - cat
    tty: true
"""
        }
    }

    triggers {
        githubPush()
    }

    environment {
        DOCKER_USERNAME = "ibrahimmintal"
        IMAGE_NAME     = "shorten-url"
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        AWS_REGION     = "us-west-2"
        EKS_CLUSTER    = "ci-cd-eks"
        NAMESPACE      = "app"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Debug Workspace') {
            steps {
                script {
                    echo "Workspace: ${env.WORKSPACE}"
                    sh """
                        echo "==== Directory Tree ===="
                        ls -R ${env.WORKSPACE}
                        echo "==== Checking Dockerfile ===="
                        find ${env.WORKSPACE} -maxdepth 3 -name 'Dockerfile'
                    """
                }
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                            echo "=== Starting Kaniko Build & Push ==="
                            /kaniko/executor \
                              --context=dir://${env.WORKSPACE}/app \
                              --dockerfile=${env.WORKSPACE}/app/Dockerfile \
                              --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} \
                              --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
                              --single-snapshot \
                              --cache=true \
                              --snapshot-mode=redo \
                              --verbosity=info
                        """
                    }
                }
            }
        }

        stage('Image pushed successfully') {
            steps {
                echo "Image pushed: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                echo "Latest tag updated."
            }
        }

        stage('Deploy to EKS') {
            steps {
                container('kubectl') {
                    withCredentials([awsAccessKeyId(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        script {
                            sh """
                                echo "=== Deploying to EKS ==="
                                export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER}
                                kubectl apply -f k8s/app_ns.yaml
                                kubectl apply -f k8s/app_service.yaml
                                kubectl apply -f k8s/app_deployment.yaml
                                kubectl set image deployment/app app=${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE}
                                kubectl rollout status deployment/app -n ${NAMESPACE} --timeout=300s
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✓ Pipeline completed successfully"
        }
        failure {
            echo "✗ Pipeline failed — check logs"
        }
        always {
            echo "Clean up complete."
        }
    }
}
