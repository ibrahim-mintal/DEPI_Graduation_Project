pipeline {
    agent {
        kubernetes {
            label 'graduation-project'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: slave
spec:
  serviceAccountName: jenkins-sa
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  volumes:
  - name: docker-config
    secret:
      secretName: regcred
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    environment {
        DOCKER_USERNAME = "ibrahimmintal"
        IMAGE_NAME = "shorten-url"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG_PATH = "/home/jenkins/agent/k8s/jenkins-kubeconfig.yaml"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
                echo "Workspace: ${env.WORKSPACE}"
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                        echo '=== Starting Kaniko Build & Push ==='
                        /kaniko/executor \\
                          --context=dir://${WORKSPACE}/app \\
                          --dockerfile=${WORKSPACE}/app/Dockerfile \\
                          --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} \\
                          --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:latest \\
                          --single-snapshot \\
                          --cache=true \\
                          --snapshot-mode=redo \\
                          --verbosity=info
                        """
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                container('kubectl') {
                    script {
                        sh """
                        export KUBECONFIG=${KUBECONFIG_PATH}
                        kubectl apply -f ${WORKSPACE}/k8s/app_ns.yaml
                        kubectl apply -f ${WORKSPACE}/k8s/app_service.yaml
                        kubectl apply -f ${WORKSPACE}/k8s/app_deployment.yaml
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Clean up complete."
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed — check logs."
        }
    }
}
