pipeline {
    agent any
    environment {
        SONAR_TOKEN = credentials('sonar-token') // Make sure this ID matches your Jenkins credentials
        PROJECT_NAME = "mydotnetapp" // lowercase for Docker compatibility
        ACR_LOGIN = "myacrregistry123456789.azurecr.io"
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

        stage('SonarQube Analysis') {
            steps {
                // Catch errors so pipeline continues even if Sonar fails
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withSonarQubeEnv('SonarQube') { // <-- Use the exact Jenkins SonarQube installation name
                        sh "dotnet tool install --global dotnet-sonarscanner || true" // Ensure the tool is available
                        sh "export PATH=\$PATH:/root/.dotnet/tools"
                        sh "dotnet sonarscanner begin /k:${PROJECT_NAME} /d:sonar.login=${SONAR_TOKEN}"
                        sh 'dotnet build ./MyApi.csproj'
                        sh "dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${PROJECT_NAME}:latest .
                """
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
                        docker login ${ACR_LOGIN} -u $ACR_USER -p $ACR_PASS
                        docker tag ${PROJECT_NAME}:latest ${ACR_LOGIN}/${PROJECT_NAME}:latest
                        docker push ${ACR_LOGIN}/${PROJECT_NAME}:latest
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
