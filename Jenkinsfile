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
  nodeSelector:
    node-role: jenkins-node
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: kubectl
    image: bitnami/kubectl:latest
    imagePullPolicy: Always
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    emptyDir: {}
"""
        }
    }

    triggers {
        githubPush()
    }

    environment {
        DOCKER_USERNAME = "ibrahimmintal"
        IMAGE_NAME = "shorten-url"

        IMAGE_TAG = "${env.BUILD_NUMBER}"
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

        stage('Set Docker Auth') {
            steps {
                container('kaniko') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                        mkdir -p /kaniko/.docker
                        cat <<EOF > /kaniko/.docker/config.json
        {
        "auths": {
            "https://index.docker.io/v1/": {
            "username": "$DOCKER_USER",
            "password": "$DOCKER_PASS",
            "auth": "$(echo -n $DOCKER_USER:$DOCKER_PASS | base64)"
            }
        }
        }
        EOF
                        '''
                    }
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
                    script {
                        sh """
                            echo "=== Deploying to EKS ==="
                            kubectl set image deployment/app app=${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} -n app
                            kubectl rollout status deployment/app -n app --timeout=300s
                        """
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
