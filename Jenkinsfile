pipeline {
  agent any

  environment {
    // change these two to match your ACR / repository if desired
    ACR_REGISTRY = "myregistry.azurecr.io"      // <-- replace with your ACR login server
    IMAGE_NAME   = "${env.ACR_REGISTRY}/mydotnetapi"
    SONAR_HOST_URL = "http://20.151.236.33:9000" // <-- replace if different
    // if you want a specific tag, set DOCKER_IMAGE_TAG credential or leave blank to use timestamp
    DOCKER_TAG = "${env.BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
  }

  options {
    // keep only last 10 builds
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Find project file') {
      steps {
        // find the project file and expose as env var for subsequent steps
        script {
          def proj = sh(returnStdout: true, script: "find . -maxdepth 3 -type f -name '*.csproj' | head -n 1").trim()
          if (!proj) {
            error "No .csproj found in workspace"
          }
          env.PROJECT_FILE = proj
          echo "Using project: ${env.PROJECT_FILE}"
        }
      }
    }

    stage('Restore & Build') {
      steps {
        // restore and build explicitly the discovered project file
        sh '''
          echo "dotnet restore ${PROJECT_FILE}"
          dotnet restore "${PROJECT_FILE}"
          echo "dotnet build ${PROJECT_FILE} -c Release"
          dotnet build "${PROJECT_FILE}" -c Release --no-restore
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        // Use Jenkins credential "sonar-token" (Secret text) and pass as SONAR_TOKEN into Docker container.
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          // triple-single-quoted string avoids Groovy interpolation of secrets and lets the shell expand $SONAR_TOKEN.
          sh '''
            echo "Running SonarScanner (Dockerized) - project key derived from repo name"
            docker run --rm \
              -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
              -e SONAR_TOKEN="$SONAR_TOKEN" \
              -v "$(pwd)":/usr/src \
              -w /usr/src \
              sonarsource/sonar-scanner-cli:latest \
              -Dsonar.projectKey=${JOB_NAME}-${BUILD_ID} \
              -Dsonar.sources=. \
              -Dsonar.host.url="${SONAR_HOST_URL}" \
              -Dsonar.login="$SONAR_TOKEN"
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // ensure tag is sane: use provided env DOCKER_TAG or default computed above
          def tag = env.DOCKER_IMAGE_TAG ?: env.DOCKER_TAG
          env.IMAGE_TAG = tag
          env.FULL_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        }
        sh '''
          echo "Building Docker image ${FULL_IMAGE}"
          docker build -t "${FULL_IMAGE}" .
          docker image inspect "${FULL_IMAGE}" > image-inspect.json || true
        '''
      }
    }

    stage('Trivy Scan') {
      steps {
        // run Trivy in Docker to scan the image; keep scan from failing the pipeline by default (use returnStatus if you want to fail)
        sh '''
          echo "Scanning ${FULL_IMAGE} with Trivy"
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL "${FULL_IMAGE}" || echo "Trivy found issues (non-zero exit); check above output"
        '''
      }
    }

    stage('Login to ACR and Push') {
      steps {
        // Use username/password credential for ACR; cred id "acr-creds"
        withCredentials([usernamePassword(credentialsId: 'acr-creds', passwordVariable: 'ACR_PASS', usernameVariable: 'ACR_USER')]) {
          sh '''
            echo "Logging into ACR ${ACR_REGISTRY}"
            echo "$ACR_PASS" | docker login ${ACR_REGISTRY} -u "$ACR_USER" --password-stdin
            echo "Pushing ${FULL_IMAGE}"
            docker push "${FULL_IMAGE}"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline completed successfully. Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
      archiveArtifacts artifacts: 'image-inspect.json', onlyIfSuccessful: true
    }
    unstable {
      echo "Pipeline finished but unstable"
    }
    failure {
      echo "Pipeline failed - check logs above"
    }
    always {
      // try to remove local built image to free space
      sh '''
        if [ -n "${FULL_IMAGE}" ]; then
          docker rmi "${FULL_IMAGE}" || true
        fi
      '''
    }
  }
}
