pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')   // Jenkins credential ID for SonarQube
        PROJECT_NAME = "mydotnetapp"               // lowercase for Docker and ACR
        ACR_NAME = "myacrregistry123456789"       // your ACR
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
                    sh 'dotnet clean ./MyApi.csproj'
                    sh 'dotnet restore ./MyApi.csproj --use-lock-file'
                    sh 'dotnet build ./MyApi.csproj -c Release --no-restore'
                }
            }
        }

        stage('Install Swagger if missing') {
            steps {
                dir('.') {
                    sh 'dotnet add ./MyApi.csproj package Swashbuckle.AspNetCore --version 6.6.1 --no-restore || echo "Swagger already installed"'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                        if ! dotnet tool list -g | grep dotnet-sonarscanner; then
                            dotnet tool install --global dotnet-sonarscanner
                            export PATH="$PATH:$HOME/.dotnet/tools"
                        fi
                        dotnet sonarscanner begin /k:${PROJECT_NAME} /d:sonar.login=${SONAR_TOKEN}
                        dotnet build ./MyApi.csproj
                        dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}
                        '''
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
                sh "trivy image ${PROJECT_NAME}:latest || echo 'Trivy scan skipped'"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
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
        always { echo "Pipeline finished!" }
        failure { echo "Pipeline failed!" }
    }
}
