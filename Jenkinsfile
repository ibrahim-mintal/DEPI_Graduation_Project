pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  nodeSelector:
    node-role: jenkins-node
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "400m"
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
      items:
      - key: config.json
        path: config.json
'''
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = 'ibrahim-mintal'  // Update this
        IMAGE_NAME = 'graduation-project'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Info') {
            steps {
                script {
                    echo "======================================"
                    echo "Building: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "======================================"
                }
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                            echo "Starting Kaniko build with minimal resources..."
                            /kaniko/executor \
                                --dockerfile=Dockerfile \
                                --context=dir://${env.WORKSPACE} \
                                --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} \
                                --destination=${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
                                --cache=false \
                                --single-snapshot \
                                --compressed-caching=false \
                                --snapshot-mode=redo \
                                --log-format=text \
                                --verbosity=info
                        """
                    }
                }
            }
        }
        
        stage('Success') {
            steps {
                script {
                    echo "======================================"
                    echo "✓ Image pushed successfully!"
                    echo "======================================"
                    echo "Pull commands:"
                    echo "  docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "  docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
                    echo "======================================"
                }
            }
        }
    }
    
    post {
        success {
            echo '✓ Pipeline completed successfully!'
        }
        failure {
            echo '✗ Pipeline failed - check logs above'
        }
        always {
            echo 'Cleaning up...'
        }
    }
}