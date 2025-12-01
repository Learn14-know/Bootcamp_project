pipeline {
    agent any

    environment {
        ACR_REGISTRY   = "myacrregistry123456789.azurecr.io"
        IMAGE_NAME     = "${env.ACR_REGISTRY}/mydotnetapi"
        SONAR_HOST_URL = "http://20.151.236.33:9000"
        DOCKER_TAG     = "${env.BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    stages {
        stage('Clean Workspace') {
            steps {
                script {
                    echo "Cleaning workspace to remove stale Git locks and old files..."
                    deleteDir()
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Workspace') {
            steps {
                script {
                    echo "Fixing permissions and cleaning old build artifacts..."
                    sh '''
                        chmod -R 775 .
                        rm -rf obj bin
                    '''
                }
            }
        }

        stage('Find project file') {
            steps {
                script {
                    def proj = sh(returnStdout: true, script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1").trim()
                    if (!proj) error "No .csproj found in workspace"
                    env.PROJECT_FILE = proj
                    echo "Using project: ${env.PROJECT_FILE}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                sh '''
                    dotnet restore "${PROJECT_FILE}"
                    dotnet build "${PROJECT_FILE}" -c Release
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        echo "Running SonarScanner via Docker..."
                        docker run --rm \
                            -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
                            -e SONAR_TOKEN="$SONAR_TOKEN" \
                            -v "$(pwd)":/usr/src \
                            -w /usr/src \
                            sonarsource/sonar-scanner-cli:latest \
                            -Dsonar.projectKey=${JOB_NAME}-${BUILD_ID} \
                            -Dsonar.sources=. \
                            -Dsonar.host.url="${SONAR_HOST_URL}" \
                            -Dsonar.login="$SONAR_TOKEN"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.FULL_IMAGE = "${IMAGE_NAME}:${DOCKER_TAG}"
                }
                sh '''
                    echo "Building Docker image ${FULL_IMAGE}"
                    docker build -t "${FULL_IMAGE}" .
                    docker image inspect "${FULL_IMAGE}" > image-inspect.json || true
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    echo "Scanning ${FULL_IMAGE} with Trivy..."
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL "${FULL_IMAGE}" || echo "Trivy found issues"
                '''
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-creds', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
                    sh '''
                        echo "$ACR_PASS" | docker login ${ACR_REGISTRY} -u "$ACR_USER" --password-stdin
                        echo "Pushing ${FULL_IMAGE}"
                        docker push "${FULL_IMAGE}"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully. Image pushed: ${FULL_IMAGE}"
            archiveArtifacts artifacts: 'image-inspect.json', onlyIfSuccessful: true
        }
        failure {
            echo "Pipeline failed - check logs above"
        }
        always {
            sh '''
                if [ -n "${FULL_IMAGE}" ]; then
                    docker rmi "${FULL_IMAGE}" || true
                fi
            '''
        }
    }
}
