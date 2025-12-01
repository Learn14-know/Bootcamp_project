pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'http://20.151.236.33:9000'
        ACR_NAME = 'myacrregistry123456789'
        IMAGE_NAME = 'mydotnetapi'
        IMAGE_TAG = 'latest'
        DOTNET_TOOLS_PATH = "${env.HOME}/.dotnet/tools"
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
                    PROJECT_DIR = sh(
                        script: "dirname ${PROJECT_FILE}",
                        returnStdout: true
                    ).trim()
                    echo "Using project file: ${PROJECT_FILE}"
                    echo "Project directory: ${PROJECT_DIR}"
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
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    script {
                        // Remove old sonar-project.properties if any
                        sh "rm -f sonar-project.properties"

                        // Ensure dotnet tools path is on PATH
                        sh "export PATH=\$PATH:${DOTNET_TOOLS_PATH}"

                        // Install dotnet-sonarscanner globally if missing
                        sh "dotnet tool install --global dotnet-sonarscanner || true"

                        // Run SonarScanner begin/build/end
                        sh """
                            export PATH=\$PATH:${DOTNET_TOOLS_PATH}
                            dotnet sonarscanner begin /k:MyDotNetApp /d:sonar.host.url=${SONAR_HOST_URL} /d:sonar.login=$SONAR_TOKEN /d:sonar.projectBaseDir=${PROJECT_DIR}
                            dotnet build ${PROJECT_FILE} -c Release
                            dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ${PROJECT_DIR}"
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
