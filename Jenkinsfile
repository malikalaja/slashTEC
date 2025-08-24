#!/usr/bin/env groovy

def branchName     = params.BranchName ?: "main"
def gitUrl         = "https://github.com/malikalaja/slashTEC.git"
def gitUrlCode     = "https://github.com/malikalaja/slashTEC.git"
def serviceType    = params.ServiceType ?: "airport-service"
def EnvName        = "preprod"
def awsAccountId   = env.AWS_ACCOUNT_ID ?: "YOUR_AWS_ACCOUNT_ID_HERE"
def awsRegion      = env.AWS_DEFAULT_REGION ?: "ap-south-1"
def registryId     = awsAccountId
def ecrUrl         = "${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = env.ARGOCD_SERVER_URL ?: "https://argocd-preprod.login.foodics.online"
def JENKINS_URL    = env.JENKINS_SERVER_URL ?: "http://13.203.7.135/"

def getServiceConfig(serviceType) {
    def config = [:]
    
    if (serviceType == "airport-service") {
        config.serviceName = "airport-service"
        config.dockerfile = "docker/Dockerfile"
        config.applicationName = "airport-services"
        config.jarFileName = "airports-assembly-1.1.0.jar"
    } else if (serviceType == "country-service") {
        config.serviceName = "country-service" 
        config.dockerfile = "docker/Dockerfile.country"
        config.applicationName = "airport-services"
        config.jarFileName = "countries-assembly-1.0.1.jar"
    } else {
        error "Unknown service type: ${serviceType}. Must be 'airport-service' or 'country-service'"
    }
    
    config.envName = "preprod"
    config.configName = "preprod"
    config.clientId = "${config.applicationName}-${config.envName}"
    config.namespace = "preprod"
    config.helmDir = "helm-unified"
    config.slashtecDir = "slashtec/slashTEC"
    
    return config
}

def config = getServiceConfig(serviceType)
def latestTagValue = params.Tag

node {
  
  try {
    if (awsAccountId == "YOUR_AWS_ACCOUNT_ID_HERE") {
      error "AWS_ACCOUNT_ID environment variable not configured. Please configure AWS credentials in Jenkins."
    }
    
          stage('cleanup') {
        cleanWs()
      }
      
      stage('Check Tools') {
        sh """
        echo "=== TOOL AVAILABILITY CHECK ==="
        echo "Git version:" 
        git --version || echo "❌ Git not found"
        echo "AWS CLI version:"
        aws --version || echo "❌ AWS CLI not found"
        echo "Docker version:"
        docker --version || echo "❌ Docker not found"
        echo "YQ version:"
        yq --version || echo "❌ YQ not found"
        echo "Java version:"
        java -version || echo "❌ Java not found"
        echo "=== END TOOL CHECK ==="
        """
      }
      
      stage ("Get the app code") {
        checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
        sh "rm -rf ~/workspace/\"${JOB_NAME}\"/slashtec"
        sh "mkdir ~/workspace/\"${JOB_NAME}\"/slashtec ; cd slashtec ; git clone -b main ${gitUrl} "
        
        
        sh("cp ${config.slashtecDir}/${config.dockerfile} ${config.dockerfile}")
        sh("cp -r ${config.slashtecDir}/docker/* .")
        sh("cp ${config.slashtecDir}/interview-test/${config.jarFileName} app.jar")
        
      
        sh("[ -d ${config.slashtecDir}/files ] && cp -r ${config.slashtecDir}/files/* . || echo 'No files directory found'")
      }
      
      stage("Get the env variables from App") {
        // Temporarily skip AppConfig - create .env with defaults for testing
        sh """
        echo 'DATABASE_URL=jdbc:postgresql://localhost:5432/airport_db' > .env
        echo 'API_ENVIRONMENT=preprod' >> .env
        echo 'LOG_LEVEL=INFO' >> .env
        echo 'AppConfig stage skipped - using default configuration for testing'
        """
      }
      
      stage('login to ecr') {
        sh("aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${ecrUrl}")
      }
      
      stage("Build Docker Image - ${config.serviceName}") {
        sh("docker build -t ${ecrUrl}/${config.serviceName}:${imageTag} -f ${config.dockerfile} .")
      }
      
      stage("Push Docker Image To ECR - ${config.serviceName}") {
        sh("docker push ${ecrUrl}/${config.serviceName}:${imageTag}")
      }
      
      stage('Clean docker images') {
        sh("docker rmi -f ${ecrUrl}/${config.serviceName}:${imageTag} || :")
      }
      
      stage ("Deploy ${config.serviceName} to ${EnvName} Environment") {
        sh ("cd ${config.slashtecDir}/${config.helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
        withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
          sh """
          cd ${config.slashtecDir}/${config.helmDir}
          git config user.name "Jenkins CI"
          git config user.email "jenkins@example.com"
          git remote set-url origin https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/malikalaja/slashTEC.git
          git pull origin main
          git add values.yaml
          git commit -m 'update ${config.serviceName} image tag to ${imageTag}' || echo 'No changes to commit'
          git push origin main
          """
        }
      }

      
      if (config.serviceName == "airport-service") {
        stage ("Deploy preprod-solo-queue to ${EnvName} Environment") {
          build job: 'preprod-solo-queue', wait: true
        }
        stage ("Deploy preprod-solo-crons to ${EnvName} Environment") {
          build job: 'preprod-solo-crons', wait: true
        }
      }

      // Trigger the other service build if BUILD_BOTH_SERVICES parameter is true
      if (params.BUILD_BOTH_SERVICES && params.BUILD_BOTH_SERVICES == true) {
        def otherService = (config.serviceName == "airport-service") ? "country-service" : "airport-service"
        stage ("Trigger ${otherService} Build") {
          build job: env.JOB_NAME, parameters: [
            string(name: 'ServiceType', value: otherService),
            string(name: 'BranchName', value: branchName),
            booleanParam(name: 'BUILD_BOTH_SERVICES', value: false) 
          ], wait: false
        }
      }

    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
      currentBuild.result = "ABORTED"
      echo "Build aborted: ${e}"
    } catch (Exception e) {
      currentBuild.result = "FAILED"
      echo "Exception type: ${e.getClass().getName()}"
      echo "Exception message: ${e.message ?: 'No message'}"
      throw e
  }
}


