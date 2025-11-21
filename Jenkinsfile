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
    some-label: graduation-project
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    args: ["999999"]
    tty: true
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
      - name: workspace-volume
        mountPath: /home/jenkins/agent
        readOnly: false
  - name: jnlp
    image: jenkins/inbound-agent:3345.v03dee9b_f88fc-1
    env:
      - name: JENKINS_PROTOCOLS
        value: "JNLP4-connect"
      - name: JENKINS_AGENT_WORKDIR
        value: "/home/jenkins/agent"
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
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_TAG = "ibrahim-mintal/graduation-project:${BUILD_NUMBER}"
        LATEST_TAG = "ibrahim-mintal/graduation-project:latest"
        DOCKERFILE_PATH = "app/Dockerfile"
        CONTEXT_DIR = "app"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Debug Workspace') {
            steps {
                echo "Workspace: ${env.WORKSPACE}"
                sh '''
                    echo ==== Directory Tree ====
                    ls -R ${WORKSPACE}
                    echo ==== Checking Dockerfile ====
                    find ${WORKSPACE} -maxdepth 3 -name Dockerfile
                '''
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                            echo '=== Starting Kaniko Build ==='
                            /kaniko/executor \
                              --context=dir://${WORKSPACE}/${CONTEXT_DIR} \
                              --dockerfile=${WORKSPACE}/${DOCKERFILE_PATH} \
                              --destination=${IMAGE_TAG} \
                              --destination=${LATEST_TAG} \
                              --single-snapshot \
                              --cache=false \
                              --snapshot-mode=redo \
                              --log-format=text \
                              --verbosity=info
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✓ Build & Push Successful!"
        }
        failure {
            echo "✗ Pipeline failed — check logs"
        }
        always {
            echo "Clean up complete."
        }
    }
}
