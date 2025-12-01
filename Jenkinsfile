pipeline {
    agent any

    environment {
        ACR_NAME = "myacrregistry123456789"
        PATH = "/home/azureuser/.dotnet/tools:$PATH"  // include dotnet-sonarscanner
        SONAR_TOKEN = credentials('sonar-token-id')  // replace with your Jenkins secret ID
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Restore & Build') {
            steps {
                dir('MyApi') {
                    sh 'dotnet restore --use-lock-file'
                    sh 'dotnet build -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            dotnet sonarscanner begin /k:mydotnetapp /d:sonar.login=$SONAR_TOKEN
                            dotnet build MyApi/MyApi.csproj
                            dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $ACR_NAME/mydotnetapp:latest ."
            }
        }

        stage('Push to ACR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-credentials-id',  // replace with your Jenkins ACR creds
                    usernameVariable: 'ACR_USERNAME',
                    passwordVariable: 'ACR_PASSWORD'
                )]) {
                    sh """
                        echo $ACR_PASSWORD | docker login $ACR_NAME.azurecr.io -u $ACR_USERNAME --password-stdin
                        docker push $ACR_NAME/mydotnetapp:latest
                    """
                }
            }
        }

    }

    post {
        always {
            echo "Pipeline finished!"
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
