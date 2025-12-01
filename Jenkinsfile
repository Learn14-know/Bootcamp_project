pipeline {
    agent any

    environment {
        ACR_NAME = "myacrregistry123456789"
        IMAGE_NAME = "mydotnetapi"
        GIT_URL = "https://github.com/Learn14-know/Bootcamp_Project"
        SONAR_HOST_URL = "http://<sonarqube-server>:9000"
        SONAR_LOGIN = credentials('sonar-token') // SonarQube token stored in Jenkins
    }

    stages {
        stage('Checkout GitHub') {
            steps {
                git branch: 'main', url: "${GIT_URL}"
            }
        }

        stage('Restore .NET Packages') {
            steps {
                sh '''
                dotnet add package Swashbuckle.AspNetCore --version 6.7.0 || true
                dotnet restore
                '''
            }
        }

        stage('Build .NET Project') {
            steps {
                sh 'dotnet build --configuration Release'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'dotnet test --no-build --verbosity normal'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh """
                sonar-scanner \
                  -Dsonar.projectKey=mydotnetapi \
                  -Dsonar.sources=. \
                  -Dsonar.host.url=${SONAR_HOST_URL} \
                  -Dsonar.login=${SONAR_LOGIN}
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${BUILD_NUMBER} .
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                trivy image --severity HIGH,CRITICAL --exit-code 1 ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }

        stage('Login to ACR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-creds',
                    usernameVariable: 'ACR_USER',
                    passwordVariable: 'ACR_PASS'
                )]) {
                    sh 'echo $ACR_PASS | docker login ${ACR_NAME}.azurecr.io -u $ACR_USER --password-stdin'
                }
            }
        }

        stage('Push Image to ACR') {
            steps {
                sh 'docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${BUILD_NUMBER}'
            }
        }
    }

    post {
        failure { echo "Pipeline failed. Check logs." }
        success { echo "Pipeline succeeded. Image pushed to ACR." }
    }
}
