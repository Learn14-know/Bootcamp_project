pipeline {
    agent any

    environment {
        ACR_NAME = "myacrregistry123456789"    // replace with your ACR name
        IMAGE_NAME = "mydotnetapi"             // Docker image name
        GIT_URL = "https://github.com/Learn14-know/Bootcamp_Project.git"
    }

    stages {

        // --------------------------
        stage('Checkout GitHub') {
            steps {
                git branch: 'main', url: "${GIT_URL}"
            }
        }

        // --------------------------
        stage('Restore .NET Packages') {
            steps {
                // Add Swagger package if missing, then restore
                sh '''
                dotnet add package Swashbuckle.AspNetCore --version 6.7.0 || true
                dotnet restore
                '''
            }
        }

        // --------------------------
        stage('Build .NET Project') {
            steps {
                sh 'dotnet build --configuration Release'
            }
        }

        // --------------------------
        stage('Run Tests') {
            steps {
                sh 'dotnet test --no-build --verbosity normal || true'
            }
        }

        // --------------------------
        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${BUILD_NUMBER} .
                """
            }
        }

        // --------------------------
        stage('Login to ACR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-creds',  // Jenkins credential ID
                    usernameVariable: 'ACR_USER',
                    passwordVariable: 'ACR_PASS'
                )]) {
                    sh """
                    echo $ACR_PASS | docker login ${ACR_NAME}.azurecr.io -u $ACR_USER --password-stdin
                    """
                }
            }
        }

        // --------------------------
        stage('Push Image to ACR') {
            steps {
                sh """
                docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }
    }

    post {
        failure {
            echo "CI Pipeline failed! Check logs."
        }
        success {
            echo "CI Pipeline succeeded! Docker image pushed to ACR."
        }
    }
}
