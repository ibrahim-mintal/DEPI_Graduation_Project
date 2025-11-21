pipeline {
    agent none

    environment {
        IMAGE_NAME = "ibrahimmintal/shorten-url"
        IMAGE_TAG = "${GIT_COMMIT}"
        KUBE_NAMESPACE_APP = "app"
        AWS_REGION = "us-west-2"
        EKS_CLUSTER_NAME = "ci-cd-eks"
    }

    stages {

        stage('Checkout') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Apply Docker Secret') {
            agent any
            steps {
                sh "kubectl apply -f k8s/docker_secret.yaml -n jenkins"
            }
        }

        stage('Build & Push Docker Image with Kaniko') {
            agent {
                kubernetes {
                    label "kaniko-${env.BUILD_NUMBER}"
                    defaultContainer 'kaniko'
                    yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["/busybox/sh"]
      tty: true
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
          readOnly: true
  restartPolicy: Never
  volumes:
    - name: kaniko-secret
      secret:
        secretName: regcred
"""
                }
            }
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                      --context dir:///workspace/app \
                      --dockerfile Dockerfile \
                      --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                      --destination=${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy App to EKS') {
            agent any
            steps {
                sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                sh "kubectl apply -f k8s/app_ns.yaml"
                sh "kubectl apply -f k8s/app_deployment.yaml -n ${KUBE_NAMESPACE_APP}"
                sh "kubectl apply -f k8s/app_service.yaml -n ${KUBE_NAMESPACE_APP}"
                sh "kubectl rollout status deployment/app -n ${KUBE_NAMESPACE_APP}"
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
