pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
    IMAGE_NAME = "shorten-url"
    IMAGE_TAG = "build-${env.BUILD_NUMBER}"
  }
  triggers {
    // Trigger pipeline on GitHub push
    githubPush()
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t $IMAGE_NAME:$IMAGE_TAG ."
      }
    }

    stage('Push to DockerHub') {
      steps {
        sh """
          echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
          docker push $DOCKERHUB_CREDENTIALS_USR/$IMAGE_NAME:$IMAGE_TAG
        """
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh """
          echo "🔧 Setting up kubeconfig (in-cluster)..."
          
          echo "Deploying to EKS cluster..."
          kubectl set image deployment/app-deployment app-container=$DOCKERHUB_CREDENTIALS_USR/$IMAGE_NAME:$IMAGE_TAG -n app-ns
          kubectl rollout restart deployment/app-deployment -n app-ns
          kubectl rollout status deployment/app-deployment -n app-ns
        """
      }
    }
  }
}
