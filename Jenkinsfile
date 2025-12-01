pipeline {
    agent any
    
    environment {
        ACR_NAME = "myacr1first234567"
        IMAGE_NAME = "mydotnetapp"
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
    }
    
    stages {
        
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/your-user/your-repo.git'
            }
        }

        stage('Restore Packages') {
            steps {
                sh 'dotnet restore'
            }
        }

        stage('Build') {
            steps {
                sh 'dotnet build --configuration Release'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'dotnet test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest ."
            }
        }

        stage('Login to ACR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-credentials',
                    usernameVariable: 'ACR_USER',
                    passwordVariable: 'ACR_PASS'
                )]) {
                    sh "docker login ${ACR_LOGIN_SERVER} -u $ACR_USER -p $ACR_PASS"
                }
            }
        }

        stage('Push Image to ACR') {
            steps {
                sh "docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
            }
        }
    }
}
