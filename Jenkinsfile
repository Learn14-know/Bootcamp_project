pipeline {
    agent any

    environment {
        // SonarQube settings
        SONAR_HOST_URL = "http://20.151.236.33:9000"
        SONAR_TOKEN = credentials('sonar-token') // replace with your Jenkins credential ID

        // Docker / ACR settings
        ACR_NAME = "myacrregistry123456789"
        IMAGE_NAME = "mydotnetapi"
        IMAGE_TAG = "latest"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                echo "Cleaning workspace to remove stale Git locks..."
                deleteDir() // wipes everything including .git folder
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Learn14-know/Bootcamp_project/',
                        credentialsId: '8b560c32-691e-4f7b-a7be-bb913f53e41b'
                    ]]
                ])
            }
        }

        stage('Find Project File') {
            steps {
                script {
                    PROJECT_FILE = sh(
                        script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1",
                        returnStdout: true
                    ).trim()
                    echo "Using project: ${PROJECT_FILE}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                sh "dotnet restore ${PROJECT_FILE}"
                sh "dotnet build ${PROJECT_FILE} -c Release --no-restore"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh """
                    dotnet sonarscanner begin /k:"mydotnetapi" /d:sonar.host.url="${SONAR_HOST_URL}" /d:sonar.login="${SONAR_TOKEN}"
                    dotnet build ${PROJECT_FILE}
                    dotnet sonarscanner end /d:sonar.login="${SONAR_TOKEN}"
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "trivy image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
                    sh """
                        echo ${ACR_PASS} | docker login ${ACR_NAME}.azurecr.io -u ${ACR_USER} --password-stdin
                        docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
