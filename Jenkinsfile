pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')  // your SonarQube token
        PROJECT_FILE = './MyApi.csproj'
        PROJECT_DIR = '.'
        IMAGE_NAME = 'mydotnetapp'  // lowercase for Docker
        ACR_NAME = 'youracrname.azurecr.io'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Restore & Build') {
            steps {
                dir(PROJECT_DIR) {
                    sh 'dotnet clean $PROJECT_FILE'           // clean to avoid stale files
                    sh 'dotnet restore $PROJECT_FILE --use-lock-file'
                    sh 'dotnet build $PROJECT_FILE -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "dotnet sonarscanner begin /k:mydotnetapp /d:sonar.login=$SONAR_TOKEN /d:sonar.host.url=$SONAR_HOST_URL"
                    sh "dotnet build $PROJECT_FILE"
                    sh "dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $ACR_NAME/$IMAGE_NAME:latest ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "trivy image --exit-code 1 $ACR_NAME/$IMAGE_NAME:latest"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh "az acr login --name $ACR_NAME"
                sh "docker push $ACR_NAME/$IMAGE_NAME:latest"
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
