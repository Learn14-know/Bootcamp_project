pipeline {
    agent any
    environment {
        PROJECT_FILE = ''
        SONAR_HOST_URL = "http://20.151.236.33:9000"
        SONAR_TOKEN = credentials('sonar-token') // Jenkins credential ID
        ACR_NAME = "myacrregistry123456789"
        IMAGE_NAME = "mydotnetapi"
        IMAGE_TAG = "latest"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[
                              url: 'https://github.com/Learn14-know/Bootcamp_project/',
                              credentialsId: '8b560c32-691e-4f7b-a7be-bb913f53e41b'
                          ]]
                ])
            }
        }

        stage('Find project file') {
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
                sh """
                    echo "Adding Swagger package..."
                    dotnet add ${PROJECT_FILE} package Swashbuckle.AspNetCore --version 6.6.0
                    echo "Restoring project..."
                    dotnet restore ${PROJECT_FILE}
                    echo "Building project..."
                    dotnet build ${PROJECT_FILE} -c Release --no-restore
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh """
                    dotnet sonarscanner begin \
                        /k:"${IMAGE_NAME}" \
                        /d:sonar.host.url="${SONAR_HOST_URL}" \
                        /d:sonar.login="${SONAR_TOKEN}"
                    dotnet build ${PROJECT_FILE} -c Release --no-restore
                    dotnet sonarscanner end /d:sonar.login="${SONAR_TOKEN}"
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                    trivy image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh """
                    az acr login --name ${ACR_NAME}
                    docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
        success {
            echo "Pipeline succeeded"
        }
        failure {
            echo "Pipeline failed - check logs above"
        }
    }
}
