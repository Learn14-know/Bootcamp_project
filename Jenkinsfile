pipeline {
    agent any
    environment {
        SONAR_TOKEN = credentials('sonar-token')
        PROJECT_NAME = "mydotnetapp"
        ACR_NAME = "myacrregistry123456789"
        PATH = "$PATH:/home/azureuser/.dotnet/tools"
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
                    // Install Swagger if missing
                    sh """
                    dotnet list package | grep Swashbuckle.AspNetCore || dotnet add ./MyApi.csproj package Swashbuckle.AspNetCore --version 6.6.1
                    """
                    
                    // Restore and build
                    sh 'dotnet restore ./MyApi.csproj --use-lock-file'
                    sh 'dotnet build ./MyApi.csproj -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withSonarQubeEnv('SonarQube') {
                        sh "dotnet sonarscanner begin /k:${PROJECT_NAME} /d:sonar.login=${SONAR_TOKEN}"
                        sh 'dotnet build ./MyApi.csproj'
                        sh "dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${PROJECT_NAME}:latest ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "trivy image ${PROJECT_NAME}:latest"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', passwordVariable: 'ACR_PASS', usernameVariable: 'ACR_USER')]) {
                    sh """
                        docker login ${ACR_NAME}.azurecr.io -u $ACR_USER -p $ACR_PASS
                        docker tag ${PROJECT_NAME}:latest ${ACR_NAME}.azurecr.io/${PROJECT_NAME}:latest
                        docker push ${ACR_NAME}.azurecr.io/${PROJECT_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
