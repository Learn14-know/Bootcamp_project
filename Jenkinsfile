pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'http://20.151.236.33:9000'
        ACR_NAME = 'myacrregistry123456789'
        IMAGE_NAME = 'MyDotNetApp'
        IMAGE_TAG = 'latest'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Learn14-know/Bootcamp_project/',
                        credentialsId: 'git-credential-id'
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
                sh """
                    # Install Swagger package if missing
                    dotnet add ${PROJECT_FILE} package Swashbuckle.AspNetCore --version 6.6.0
                    dotnet restore ${PROJECT_FILE}
                    dotnet build ${PROJECT_FILE} -c Release --no-restore
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        # Install SonarScanner for .NET globally if not installed
                        dotnet tool install --global dotnet-sonarscanner || true
                        export PATH="\$PATH:\$HOME/.dotnet/tools"

                        # Begin SonarQube analysis
                        dotnet sonarscanner begin \
                            /k:${IMAGE_NAME} \
                            /d:sonar.host.url=${SONAR_HOST_URL} \
                            /d:sonar.login=${SONAR_TOKEN} \
                            /s:SonarQube.AnalysisSettings.xml

                        # Build project for analysis
                        dotnet build ${PROJECT_FILE} -c Release

                        # End SonarQube analysis
                        dotnet sonarscanner end /d:sonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials-id', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
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
