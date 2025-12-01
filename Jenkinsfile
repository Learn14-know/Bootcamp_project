pipeline {
    agent any

    environment {
        DOTNET_ROOT = "$HOME/dotnet"
        PATH = "$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
        ACR_NAME = "myacrregistry123456789"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Swagger if missing') {
            steps {
                sh '''
                    echo "Installing Swashbuckle.AspNetCore if not already installed..."
                    dotnet add ./MyApi.csproj package Swashbuckle.AspNetCore --version 6.6.1 --no-restore || true
                    dotnet restore ./MyApi.csproj --use-lock-file
                '''
            }
        }

        stage('Restore & Build') {
            steps {
                sh '''
                    echo "Building the project..."
                    dotnet build ./MyApi.csproj -c Release --no-restore
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            echo "Running SonarQube Analysis..."
                            dotnet sonarscanner begin /k:MyDotNetApp /d:sonar.login=$SONAR_TOKEN
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
                    echo "Building Docker image..."
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
                withCredentials([
                    string(credentialsId: 'jenkins-acr-sp', variable: 'CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'TENANT_ID')
                ]) {
                    // For SP, we also need the App ID
                    env.CLIENT_ID = 'c03990aa-a13c-4bc2-84b7-6e0350b00eff'
                    
                    sh '''
                    echo "Logging in with Service Principal..."
                    az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
                    az acr login --name myacrregistry123456789
                    docker push myacrregistry123456789.azurecr.io/mydotnetapp:latest
                    '''
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
