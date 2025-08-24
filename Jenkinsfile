def branchName     = params.BranchName ?: "main"
def gitUrl         = "git@github.com:malikalaja/slashTEC.git"
def gitUrlCode     = "git@github.com:malikalaja/slashTEC.git"
def serviceName    = "airport-service"
def EnvName        = "preprod"
def registryId     = "${AWS_ACCOUNT_ID}"
def awsRegion      = "ap-south-1"
def ecrUrl         = "727245885999.dkr.ecr.ap-south-1.amazonaws.com"
def dockerfile     = "docker/Dockerfile"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "https://argocd-preprod.login.foodics.online"


def applicationName = "airport-countries"
def envName = "preprod"
def configName = "preprod"

def clientId = "${applicationName}-${envName}"
def latestTagValue = params.Tag
def namespace = "preprod"
def helmDir = "helm-unified"
def slashtecDir = "slashtec/slashTEC"



node {
  try {
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
          echo "Available JAR files in interview-test/:"
          ls -la interview-test/*.jar || echo "No JAR files found"
          echo "Using airports-assembly-1.1.0.jar for Docker build"
          
          echo "Preparing Docker build context..."
          cp interview-test/airports-assembly-1.1.0.jar docker/app.jar || echo "Warning: No JAR files copied"
          
          echo "Files in docker directory:"
          ls -la docker/
          
          echo "Building Docker image..."
          docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} docker/
          
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
        sh ("cd slachTec/${helmDir}; pathEnv=\".values.airportService.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
        sh ("cd slashTec/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
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
      // Slack notifications removed
    }
}

