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
  - name: jnlp
    image: jenkins/inbound-agent:3345.v03dee9b_f88fc-1
    env:
    - name: JENKINS_AGENT_WORKDIR
      value: /home/jenkins/agent
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
      readOnly: false
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
      items:
      - key: config.json
        path: config.json
  - emptyDir: {}
    name: workspace-volume
"""
        }
    }

    triggers {
        githubPush()
    }

    environment {
        DOCKER_USERNAME = "ibrahim-mintal"
        IMAGE_NAME = "graduation-project"
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

        stage('Success') {
            steps {
                echo "Image pushed successfully: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                echo "Latest tag updated."
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
