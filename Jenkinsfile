def branchName     = params.BranchName ?: "main"
def gitUrl         = "https://github.com/ghadeerhamdan-cmd/slashtec.git"
def gitUrlCode     = "https://github.com/ghadeerhamdan-cmd/slashtec.git"
def serviceName    = "slashtec-service"
def EnvName        = "preprod"
def registryId     = "727245885999"
def awsRegion      = "ap-south-1"
def ecrUrl         = "727245885999.dkr.ecr.ap-south-1.amazonaws.com/ghadeerecr"
def dockerfile     = "dockerfile/Dockerfile"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "https://argocd-preprod.login.foodics.online"

// AppConfig Params
def applicationName = "airport-countries"
def envName = "preprod"
def configName = "preprod"
// Fix: Use string concatenation, not arithmetic
def clientId = "${applicationName}-${envName}"
def latestTagValue = params.Tag
def namespace = "preprod"
def helmDir = "helm/helm"
def slashtecDir = "helm"

def notifyBuild(String buildStatus = 'STARTED', String branch = 'main') {
  buildStatus =  buildStatus ?: 'SUCCESS'
  
  String color = 'good'
  String summary = "${buildStatus}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
  
  if (buildStatus == 'STARTED') {
    color = 'warning'
  } else if (buildStatus == 'FAILURE') {
    color = 'danger'
  }
  
  String slackMessage = """
  {
    "attachments": [
      {
        "color": "${color}",
        "fields": [
          {
            "title": "Build Status",
            "value": "${summary}",
            "short": false
          },
          {
            "title": "Branch",
            "value": "${branch}",
            "short": true
          },
          {
            "title": "Build URL",
            "value": "${env.BUILD_URL}",
            "short": false
          }
        ]
      }
    ]
  }
  """
  
  try {
    withCredentials([string(credentialsId: 'foodics-slack-online-deployments', variable: 'SLACK_WEBHOOK')]) {
      httpRequest(
        url: env.SLACK_WEBHOOK,
        httpMode: 'POST',
        contentType: 'APPLICATION_JSON',
        requestBody: slackMessage
      )
    }
  } catch (Exception e) {
    echo "Slack notification skipped: ${e.getMessage()}"
  }
}

node {
  try {
    notifyBuild('STARTED', branchName)
      stage('cleanup') {
        cleanWs()
      }
      stage ("Get the app code") {
        checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
        sh "rm -rf ${WORKSPACE}/slashtec"
        sh "mkdir -p ${WORKSPACE}/slashtec && cd ${WORKSPACE}/slashtec && git clone -b main ${gitUrl} ."
        sh("cp dockerfile/* . || echo 'No files in dockerfile directory'")
        sh("ls -la")
      }
      stage("Get the env variables from App") {
        sh """
          echo "=== Environment Configuration ==="
          echo "Application: ${applicationName}"
          echo "Environment: ${envName}"
          echo "Region: ${awsRegion}"
          
          if command -v aws &> /dev/null; then
            echo "AWS CLI found, attempting to fetch configuration..."
            aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion} || {
              echo "AWS AppConfig fetch failed, creating fallback environment..."
              echo "# Fallback environment configuration" > .env
              echo "ENVIRONMENT=${envName}" >> .env
              echo "SERVICE_PORT=8080" >> .env
              echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
            }
          else
            echo "AWS CLI not found on Jenkins server"
            echo "Creating comprehensive fallback .env file..."
            echo "# Fallback environment configuration" > .env
            echo "ENVIRONMENT=${envName}" >> .env
            echo "SERVICE_PORT=8080" >> .env
            echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
            echo "AWS_REGION=${awsRegion}" >> .env
            echo "APPLICATION_NAME=${applicationName}" >> .env
            echo "Log level set to INFO for ${envName} environment" >> .env
          fi
          
          echo "Environment file contents:"
          cat .env || echo "No .env file created"
        """
      }
      stage('login to ecr') {
        sh("aws ecr get-login-password --region ${awsRegion}  | docker login --username AWS --password-stdin ${ecrUrl}")
      }
      stage('Build Docker Image') {
        sh """
          echo "=== Docker Build Debug Info ==="
          echo "Service Name: ${serviceName}"
          echo "ECR URL: ${ecrUrl}"
          echo "Image Tag: ${imageTag}"
          echo "Dockerfile: ${dockerfile}"
          echo "Available JAR files in helm/:"
          ls -la helm/*.jar || echo "No JAR files found"
          
          echo "Preparing Docker build context..."
          cp helm/*.jar dockerfile/ || echo "Warning: No JAR files copied"
          
          echo "Files in dockerfile directory:"
          ls -la dockerfile/
          
          echo "Building Docker image..."
          docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} dockerfile/
          
          echo "=== Build Complete ==="
        """
      }
      stage('Push Docker Image To ECR') {
        sh("docker push ${ecrUrl}/${serviceName}:${imageTag}")
      }
      stage('Clean docker images') {
        sh("docker rmi -f ${ecrUrl}/${serviceName}:${imageTag} || :")
      }
      stage ("Deploy ${serviceName} to ${EnvName} Environment") {
        sh ("cd slashtec/${helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
        sh ("cd slashtec/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
      }

      // stage ("Deploy preprod-solo-queue to ${EnvName} Environment") {
      //   build job: 'preprod-solo-queue', wait: true
      // }
      // stage ("Deploy preprod-solo-crons to ${EnvName} Environment") {
      //   build job: 'preprod-solo-crons', wait: true
      // }
    } catch (Exception e) {
      currentBuild.result = 'FAILURE'
      throw e
    } finally {
      notifyBuild(currentBuild.result ?: 'SUCCESS', branchName)
    }
}