pipeline {
  agent {
    kubernetes {
      label 'kaniko-agent'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0
    tty: true
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker/
  volumes:
  - name: kaniko-secret
    secret:
      secretName: regcred
"""
    }
  }

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
    IMAGE_NAME = "shorten-url"
    IMAGE_TAG = "build-${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Push Image') {
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \
              --context=/home/jenkins/agent/workspace/\$JOB_NAME/app \
              --dockerfile=/home/jenkins/agent/workspace/\$JOB_NAME/app/Dockerfile \
              --destination=\$DOCKERHUB_CREDENTIALS_USR/\$IMAGE_NAME:\$IMAGE_TAG \
              --destination=\$DOCKERHUB_CREDENTIALS_USR/\$IMAGE_NAME:latest \
              --cache=true
          """
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh """
          kubectl set image deployment/app-deployment app-container=\$DOCKERHUB_CREDENTIALS_USR/\$IMAGE_NAME:\$IMAGE_TAG -n app-ns
          kubectl rollout restart deployment/app-deployment -n app-ns
          kubectl rollout status deployment/app-deployment -n app-ns
        """
      }
    }
  }
}
