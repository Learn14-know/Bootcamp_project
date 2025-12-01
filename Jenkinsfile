pipeline {
    agent any

    environment {
        DOTNET_ROOT = "$HOME/.dotnet"
        PATH = "$HOME/.dotnet/tools:$PATH:$PATH"
        ACR_NAME = "myacrregistry123456789"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Restore & Build') {
            steps {
                sh 'dotnet restore ./MyApi.csproj --use-lock-file'
                sh 'dotnet build ./MyApi.csproj -c Release --no-restore'
            }
        }

        stage('Install Swagger if missing') {
            steps {
                sh 'dotnet add ./MyApi.csproj package Swashbuckle.AspNetCore --version 6.6.1 --no-restore || true'
                sh 'dotnet restore ./MyApi.csproj --use-lock-file'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            export PATH="$HOME/.dotnet/tools:$PATH"
                            dotnet sonarscanner begin /k:mydotnetapp /d:sonar.login=$SONAR_TOKEN
                            dotnet build ./MyApi.csproj
                            dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t $ACR_NAME/mydotnetapp:latest -f Dockerfile .
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh 'trivy image $ACR_NAME/mydotnetapp:latest || true'
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh '''
                    az acr login --name $ACR_NAME
                    docker push $ACR_NAME/mydotnetapp:latest
                '''
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
