pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')
        ACR_NAME = 'myacrregistry123456789'
        IMAGE_NAME = 'mydotnetapp' // lowercase required for Docker
        IMAGE_TAG = 'latest'
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
                    // Find first .csproj in repo
                    def projFile = sh(script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1", returnStdout: true).trim()
                    def projDir = sh(script: "dirname ${projFile}", returnStdout: true).trim()
                    env.PROJECT_FILE = projFile
                    env.PROJECT_DIR = projDir
                    echo "Using project file: ${env.PROJECT_FILE}"
                    echo "Project directory: ${env.PROJECT_DIR}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh "dotnet restore ${env.PROJECT_FILE}"
                    // Ensure Swashbuckle.AspNetCore package is installed
                    sh "dotnet add ${env.PROJECT_FILE} package Swashbuckle.AspNetCore --version 6.6.0 || true"
                    sh "dotnet build ${env.PROJECT_FILE} -c Release --no-restore"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withEnv(["PATH+DOTNET=/var/lib/jenkins/.dotnet/tools"]) {
                    sh '''
                        dotnet tool install --global dotnet-sonarscanner || true
                        export PATH="$PATH:/var/lib/jenkins/.dotnet/tools"
                        dotnet sonarscanner begin /k:mydotnetapp /d:sonar.host.url=http://20.151.236.33:9000 /d:sonar.login=${SONAR_TOKEN}
                        dotnet build ${PROJECT_FILE}
                        dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "trivy image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                sh '''
                    az acr login --name ${ACR_NAME}
                    docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
