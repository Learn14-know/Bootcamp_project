pipeline {
    agent any

    environment {
        ACR_REGISTRY = 'myacrregistry123456789.azurecr.io'
        IMAGE_NAME = 'mydotnetapp'  // lowercase for Docker
        SONAR_HOST_URL = 'http://20.151.236.33:9000'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                git(
                    url: 'https://github.com/Learn14-know/Bootcamp_project',
                    credentialsId: 'git-credential-id',
                    branch: 'main'
                )
            }
        }

        stage('Find Project File') {
            steps {
                script {
                    PROJECT_FILE = sh(script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1", returnStdout: true).trim()
                    PROJECT_DIR = sh(script: "dirname ${PROJECT_FILE}", returnStdout: true).trim()
                    echo "Using project file: ${PROJECT_FILE}"
                    echo "Project directory: ${PROJECT_DIR}"
                }
            }
        }

        stage('Restore & Build') {
            steps {
                dir("${PROJECT_DIR}") {
                    sh 'dotnet restore ${PROJECT_FILE}'
                    sh 'dotnet build ${PROJECT_FILE} -c Release --no-restore'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    dir("${PROJECT_DIR}") {
                        sh '''
                            dotnet tool install --global dotnet-sonarscanner
                            export PATH="$PATH:/var/lib/jenkins/.dotnet/tools"
                            dotnet sonarscanner begin /k:mydotnetapp /d:sonar.host.url=$SONAR_HOST_URL /d:sonar.login=$SONAR_TOKEN
                            dotnet build ${PROJECT_FILE}
                            dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ACR_REGISTRY}/${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    sh "trivy image ${ACR_REGISTRY}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Login to ACR and Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
                    sh '''
                        echo $ACR_PASS | docker login ${ACR_REGISTRY} -u $ACR_USER --password-stdin
                        docker push ${ACR_REGISTRY}/${IMAGE_NAME}:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
    }
}
