pipeline {
    agent any

    environment {
        // Add other environment variables here
        ACR_REGISTRY = "myacrregistry123456789.azurecr.io"
        IMAGE_NAME = "mydotnetapp" // lowercase for Docker
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Restore & Build') {
            steps {
                dir('.') {
                    sh 'dotnet restore'
                    sh 'dotnet build -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // Only change: using correct credential ID for SonarQube
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh "dotnet sonarscanner begin /k:MyDotNetApp /d:sonar.login=${SONAR_TOKEN} /d:sonar.host.url=http://<SONARQUBE_SERVER>:9000"
                    sh 'dotnet build' // SonarScanner needs a build step
                    sh "dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Only change: IMAGE_NAME is lowercase
                sh "docker build -t ${ACR_REGISTRY}/${IMAGE_NAME}:latest ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${ACR_REGISTRY}/${IMAGE_NAME}:latest"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', passwordVariable: 'ACR_PASS', usernameVariable: 'ACR_USER')]) {
                    sh "docker login ${ACR_REGISTRY} -u ${ACR_USER} -p ${ACR_PASS}"
                    sh "docker push ${ACR_REGISTRY}/${IMAGE_NAME}:latest"
                }
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
