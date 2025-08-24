#!/usr/bin/env groovy

def branchName     = params.BranchName ?: "main"
def gitUrl         = "https://github.com/malikalaja/slashTEC.git"
def gitUrlCode     = "https://github.com/malikalaja/slashTEC.git"
def serviceType    = params.ServiceType ?: "airport-service" // airport-service or country-service
def EnvName        = "preprod"
def registryId     = "${AWS_ACCOUNT_ID}"
def awsRegion      = "ap-south-1"
def ecrUrl         = "${AWS_ACCOUNT_ID}.dkr.ecr.${awsRegion}.amazonaws.com"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "${ARGOCD_SERVER_URL}"
def JENKINS_URL    = "${JENKINS_SERVER_URL}"

// Service-specific configuration
def getServiceConfig(serviceType) {
    def config = [:]
    
    if (serviceType == "airport-service") {
        config.serviceName = "airport-service"
        config.dockerfile = "docker/Dockerfile"
        config.applicationName = "airport-services"
    } else if (serviceType == "country-service") {
        config.serviceName = "country-service" 
        config.dockerfile = "docker/Dockerfile.country"
        config.applicationName = "airport-services"
    } else {
        error "Unknown service type: ${serviceType}. Must be 'airport-service' or 'country-service'"
    }
    
    config.envName = "preprod"
    config.configName = "preprod"
    config.clientId = "${config.applicationName}-${config.envName}"
    config.namespace = "preprod"
    config.helmDir = "helm-unified"
    config.slashtecDir = "slashtec"
    
    return config
}

def config = getServiceConfig(serviceType)
def latestTagValue = params.Tag

node {
  withCredentials([string(credentialsId: 'slack-webhook-credentials', variable: 'SLACK_WEBHOOK')]) {
    try {
      notifyBuild('STARTED', "Building ${config.serviceName}")
      
      stage('cleanup') {
        cleanWs()
      }
      
      stage ("Get the app code") {
        checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
        sh "rm -rf ~/workspace/\"${JOB_NAME}\"/slashtec"
        sh "mkdir ~/workspace/\"${JOB_NAME}\"/slashtec ; cd slashtec ; git clone -b main ${gitUrl} "
        
        // Copy the appropriate Dockerfile based on service type
        sh("cp ${config.slashtecDir}/${config.dockerfile} ${config.dockerfile}")
        sh("cp -r ${config.slashtecDir}/docker/* .")
        sh("cp -r ${config.slashtecDir}/interview-test/*.jar .")
        
        // Copy files if directory exists
        sh("[ -d ${config.slashtecDir}/files ] && cp -r ${config.slashtecDir}/files/* . || echo 'No files directory found'")
      }
      
      stage("Get the env variables from App") {
        sh "aws appconfig get-configuration --application ${config.applicationName} --environment ${config.envName} --configuration ${config.configName} --client-id ${config.clientId} .env --region ${awsRegion}"
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
        sh ("cd slashtec/${config.helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
        sh ("cd slashtec/${config.helmDir}; git pull ; git add values.yaml; git commit -m 'update ${config.serviceName} image tag to ${imageTag}' ;git push ${gitUrl}")
      }

      // Deploy additional services if this is airport-service (primary service)
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
            booleanParam(name: 'BUILD_BOTH_SERVICES', value: false) // Prevent infinite loop
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
    } finally {
      notifyBuild(currentBuild.result, "Finished ${config.serviceName}")
    }
  }
}

def notifyBuild(String buildStatus = 'STARTED', String serviceName = '') {
    buildStatus = buildStatus ?: 'SUCCESS'

    def colorName = 'RED'
    def colorCode = '#FF0000'
    def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' ${serviceName}"
    def summary = "${subject} (${env.BUILD_URL})"

    if (buildStatus == 'STARTED') {
        color = 'YELLOW'
        colorCode = '#FFFF00'
    } else if (buildStatus == 'SUCCESS') {
        color = 'GREEN'
        colorCode = '#00FF00'
    } else {
        color = 'RED'
        colorCode = '#FF0000'
    }

    def slackMessage = [
        channel: '#deployments',
        color: colorCode,
        message: summary
    ]

    try {
        if (env.SLACK_WEBHOOK) {
            sh """
            curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"${summary}"}' \
            ${env.SLACK_WEBHOOK}
            """
        }
    } catch (Exception e) {
        echo "Failed to send Slack notification: ${e.message}"
    }
}
