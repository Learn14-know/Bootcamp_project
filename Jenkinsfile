pipeline {
    agent any

    environment {
        // SonarQube token stored in Jenkins credentials (type: Secret Text)
        SONAR_TOKEN = credentials('sonar-token')
        // Azure Container Registry login
        ACR_REGISTRY = 'myacrregistry123456789.azurecr.io'
        IMAGE_NAME = 'mydotnetapp'  // lowercase for Docker
        IMAGE_TAG = 'latest'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Start SonarQube scanner
                    sh """
                    dotnet sonarscanner begin \
                        /k:MyDotNetApp \
                        /d:sonar.login=${SONAR_TOKEN} \
                        /d:sonar.host.url=http://your-sonarqube-server:9000
                    """
                    
                    // Restore & build
                    sh 'dotnet restore'
                    sh 'dotnet build -c Release --no-restore'
                    
                    // End SonarQube scanner
                    sh "dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImage = "${ACR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker build -t ${dockerImage} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def dockerImage = "${ACR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    // Login to ACR (assuming az CLI installed)
                    sh "az acr login --name myacrregistry123456789"
                    sh "docker push ${dockerImage}"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs!'
        }
    }
}
