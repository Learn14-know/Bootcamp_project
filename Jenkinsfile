pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')
        ACR_NAME = 'myacrname'
        IMAGE_NAME = 'mydotnetapp' // lowercase for Docker
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Restore & Build') {
            steps {
                dir('.') {
                    // Clean previous build outputs
                    sh 'dotnet clean ./MyApi.csproj'

                    // Ensure Swashbuckle is installed and restore packages
                    sh 'dotnet add ./MyApi.csproj package Swashbuckle.AspNetCore --version 6.6.1 --no-restore'
                    sh 'dotnet restore ./MyApi.csproj --use-lock-file'

                    // Build the project
                    sh 'dotnet build ./MyApi.csproj -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh "dotnet sonarscanner begin /k:mydotnetapp /d:sonar.login=${SONAR_TOKEN}"
                    sh 'dotnet build ./MyApi.csproj'
                    sh "dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}"
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
                sh "trivy image --severity HIGH,CRITICAL ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh "az acr login --name ${ACR_NAME}"
                sh "docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

    }

    post {
        always {
            echo 'Pipeline finished!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
