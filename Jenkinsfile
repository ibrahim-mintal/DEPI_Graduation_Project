pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    command:
    - /busybox/sleep
    args:
    - "999999"
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  - name: jnlp
    image: jenkins/inbound-agent:latest
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_NAME = "ibrahim-mintal/graduation-project"
        BUILD_CONTEXT = "/home/jenkins/agent/workspace/Graduation_Project/app"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    sh """
                        echo "=== Using Context: ${BUILD_CONTEXT} ==="
                        echo "=== Dockerfile Path: ${BUILD_CONTEXT}/Dockerfile ==="

                        /kaniko/executor \
                          --context=dir://${BUILD_CONTEXT} \
                          --dockerfile=Dockerfile \
                          --destination=${IMAGE_NAME}:${BUILD_NUMBER} \
                          --destination=${IMAGE_NAME}:latest \
                          --single-snapshot \
                          --snapshot-mode=redo \
                          --cache=false
                    """
                }
            }
        }

        stage('Success') {
            when { success() }
            steps {
                echo "✓ Build & Push Successful!"
            }
        }
    }

    post {
        always {
            echo "Cleanup complete."
        }
        failure {
            echo "✗ Pipeline failed — check logs"
        }
    }
}
