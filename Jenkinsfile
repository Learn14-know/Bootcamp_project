pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token-id')  // your SonarQube token in Jenkins
        ACR_REGISTRY = 'myacrregistry123456789.azurecr.io'
        IMAGE_NAME = 'mydotnetapp'                   // lowercase for Docker
        DOTNET_TOOLS = "${env.HOME}/.dotnet/tools"
        PATH = "${env.PATH}:${env.DOTNET_TOOLS}"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Find Project File') {
            steps {
                script {
                    // Find the first .csproj file
                    def proj = sh(script: "find . -maxdepth 3 -name '*.csproj' | head -n 1", returnStdout: true).trim()
                    env.PROJECT_FILE = proj
                    env.PROJECT_DIR = sh(script: "dirname ${proj}", returnStdout: true).trim()
                    echo "Using project file: ${env.PROJECT_FILE}"
                    echo "Project directory: ${env.PROJECT_DIR}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh 'dotnet restore'
                    sh 'dotnet build -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh '''
                    dotnet tool install --global dotnet-sonarscanner || true
                    export PATH=$PATH:${DOTNET_TOOLS}
                    dotnet sonarscanner begin \
                        /k:mydotnetapp \
                        /d:sonar.host.url=http://20.151.236.33:9000 \
                        /d:sonar.login=${SONAR_TOKEN} \
                        /s:SonarQube.AnalysisSettings.xml || true
                    dotnet build -c Release
                    dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${ACR_REGISTRY}/${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                    trivy image ${ACR_REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh """
                    az acr login --name myacrregistry123456789
                    docker push ${ACR_REGISTRY}/${IMAGE_NAME}:latest
                """
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
