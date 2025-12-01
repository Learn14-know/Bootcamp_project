pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'http://20.151.236.33:9000'
        ACR_NAME = 'myacrregistry123456789'
        IMAGE_NAME = 'mydotnetapi'
        IMAGE_TAG = 'latest'
        PROJECT_FILE = ''
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Learn14-know/Bootcamp_project/',
                        credentialsId: 'git-credential-id'
                    ]]
                ])
            }
        }

        stage('Find Project File') {
            steps {
                script {
                    PROJECT_FILE = sh(
                        script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1",
                        returnStdout: true
                    ).trim()
                    echo "Using project: ${PROJECT_FILE}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                // Install Swagger package dynamically to fix CS1061 errors
                sh "dotnet add ${PROJECT_FILE} package Swashbuckle.AspNetCore --version 6.7.0"

                sh "dotnet restore ${PROJECT_FILE}"
                sh "dotnet build ${PROJECT_FILE} -c Release --no-restore"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    // Use SonarScanner Docker image to avoid dotnet-sonarscanner installation issues
                    sh """
                        docker run --rm \
                            -e SONAR_HOST_URL=${SONAR_HOST_URL} \
                            -e SONAR_LOGIN=${SONAR_TOKEN} \
                            -v "\$(pwd)":/usr/src \
                            -w /usr/src \
                            sonarsource/sonar-scanner-cli:latest \
                            -Dsonar.projectKey=${IMAGE_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=\${SONAR_HOST_URL} \
                            -Dsonar.login=\${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials-id', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
                    sh """
                        echo ${ACR_PASS} | docker login ${ACR_NAME}.azurecr.io -u ${ACR_USER} --password-stdin
                        docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished!"
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
