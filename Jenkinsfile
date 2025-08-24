#!/usr/bin/env groovy

def branchName     = params.BranchName ?: "main"
def gitUrl         = "https://github.com/malikalaja/slashTEC.git"
def gitUrlCode     = "https://github.com/malikalaja/slashTEC.git"
def serviceType    = params.ServiceType ?: "airport-service"
def EnvName        = "preprod"
def awsAccountId   = env.AWS_ACCOUNT_ID ?: ${AWS_ACCOUNT_ID}  // Replace with your actual AWS Account ID
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

def notifyBuild(String buildStatus = 'STARTED', String branch = 'main') {
  buildStatus =  buildStatus ?: 'SUCCESS'
  
  // Fixed: Use def keyword for local variables
  def color = 'good'
  def summary = "${buildStatus}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
  
  if (buildStatus == 'STARTED') {
    color = 'warning'
  } else if (buildStatus == 'FAILURE') {
    color = 'danger'
  }
  
  def slackMessage = """
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
        // Fixed: Use config variables instead of undefined variables
        sh """
          echo "=== Environment Configuration ==="
          echo "Application: ${config.applicationName}"
          echo "Environment: ${config.envName}"
          echo "Region: ${awsRegion}"
          
          if command -v aws &> /dev/null; then
            echo "AWS CLI found, attempting to fetch configuration..."
            aws appconfig get-configuration --application ${config.applicationName} --environment ${config.envName} --configuration ${config.configName} --client-id ${config.clientId} .env --region ${awsRegion} || {
              echo "AWS AppConfig fetch failed, creating fallback environment..."
              echo "# Fallback environment configuration" > .env
              echo "ENVIRONMENT=${config.envName}" >> .env
              echo "SERVICE_PORT=8080" >> .env
              echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
            }
          else
            echo "AWS CLI not found on Jenkins server"
            echo "Creating comprehensive fallback .env file..."
            echo "# Fallback environment configuration" > .env
            echo "ENVIRONMENT=${config.envName}" >> .env
            echo "SERVICE_PORT=8080" >> .env
            echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
            echo "AWS_REGION=${awsRegion}" >> .env
            echo "APPLICATION_NAME=${config.applicationName}" >> .env
            echo "Log level set to INFO for ${config.envName} environment" >> .env
          fi
          
          echo "Environment file contents:"
          cat .env || echo "No .env file created"
        """
      }
      stage('login to ecr') {
        // Added AWS credentials wrapper
        withCredentials([usernamePassword(credentialsId: 'aws-credentials', 
                                         usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh """
            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
            export AWS_DEFAULT_REGION=${awsRegion}
            aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${ecrUrl}
          """
        }
      }
      stage('Build Docker Image') {
        sh """
          echo "=== Docker Build Debug Info ==="
          echo "Service Name: ${config.serviceName}"
          echo "ECR URL: ${ecrUrl}"
          echo "Image Tag: ${imageTag}"
          echo "Dockerfile: ${config.dockerfile}"
          echo "Available JAR files in helm/:"
          ls -la helm/*.jar || echo "No JAR files found"
          
          echo "Preparing Docker build context..."
          cp helm/*.jar dockerfile/ || echo "Warning: No JAR files copied"
          
          echo "Files in dockerfile directory:"
          ls -la dockerfile/
          
          echo "Building Docker image..."
          docker build -t ${ecrUrl}/${config.serviceName}:${imageTag} -f ${config.dockerfile} dockerfile/
          
          echo "=== Build Complete ==="
        """
      }
      stage('Push Docker Image To ECR') {
        sh("docker push ${ecrUrl}/${config.serviceName}:${imageTag}")
      }
      stage('Clean docker images') {
        sh("docker rmi -f ${ecrUrl}/${config.serviceName}:${imageTag} || :")
      }
      stage ("Deploy ${config.serviceName} to ${EnvName} Environment") {
        sh ("cd slashtec/${config.helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
        sh ("cd slashtec/${config.helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
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



























































// def branchName     = params.BranchName ?: "main"
// def gitUrl         = "https://github.com/ghadeerhamdan-cmd/slashtec.git"
// def gitUrlCode     = "https://github.com/ghadeerhamdan-cmd/slashtec.git"
// def serviceName    = "slashtec-service"
// def EnvName        = "preprod"
// def registryId     = "727245885999"
// def awsRegion      = "ap-south-1"
// def ecrUrl         = "727245885999.dkr.ecr.ap-south-1.amazonaws.com/ghadeerecr"
// def dockerfile     = "dockerfile/Dockerfile"
// def imageTag       = "${EnvName}-${BUILD_NUMBER}"
// def ARGOCD_URL     = "https://argocd-preprod.login.foodics.online"

// // AppConfig Params
// def applicationName = "airport-countries"
// def envName = "preprod"
// def configName = "preprod"
// // Fix: Use string concatenation, not arithmetic
// def clientId = "${applicationName}-${envName}"
// def latestTagValue = params.Tag
// def namespace = "preprod"
// def helmDir = "helm/helm"
// def slashtecDir = "helm"

// def notifyBuild(String buildStatus = 'STARTED', String branch = 'main') {
//   buildStatus =  buildStatus ?: 'SUCCESS'
  
//   String color = 'good'
//   String summary = "${buildStatus}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
  
//   if (buildStatus == 'STARTED') {
//     color = 'warning'
//   } else if (buildStatus == 'FAILURE') {
//     color = 'danger'
//   }
  
//   String slackMessage = """
//   {
//     "attachments": [
//       {
//         "color": "${color}",
//         "fields": [
//           {
//             "title": "Build Status",
//             "value": "${summary}",
//             "short": false
//           },
//           {
//             "title": "Branch",
//             "value": "${branch}",
//             "short": true
//           },
//           {
//             "title": "Build URL",
//             "value": "${env.BUILD_URL}",
//             "short": false
//           }
//         ]
//       }
//     ]
//   }
//   """
  
//   try {
//     withCredentials([string(credentialsId: 'foodics-slack-online-deployments', variable: 'SLACK_WEBHOOK')]) {
//       httpRequest(
//         url: env.SLACK_WEBHOOK,
//         httpMode: 'POST',
//         contentType: 'APPLICATION_JSON',
//         requestBody: slackMessage
//       )
//     }
//   } catch (Exception e) {
//     echo "Slack notification skipped: ${e.getMessage()}"
//   }
// }

// node {
//   try {
//     notifyBuild('STARTED', branchName)
//       stage('cleanup') {
//         cleanWs()
//       }
//       stage ("Get the app code") {
//         checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
//         sh "rm -rf ${WORKSPACE}/slashtec"
//         sh "mkdir -p ${WORKSPACE}/slashtec && cd ${WORKSPACE}/slashtec && git clone -b main ${gitUrl} ."
//         sh("cp dockerfile/* . || echo 'No files in dockerfile directory'")
//         sh("ls -la")
//       }
//       stage("Get the env variables from App") {
//         sh """
//           echo "=== Environment Configuration ==="
//           echo "Application: ${applicationName}"
//           echo "Environment: ${envName}"
//           echo "Region: ${awsRegion}"
          
//           if command -v aws &> /dev/null; then
//             echo "AWS CLI found, attempting to fetch configuration..."
//             aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion} || {
//               echo "AWS AppConfig fetch failed, creating fallback environment..."
//               echo "# Fallback environment configuration" > .env
//               echo "ENVIRONMENT=${envName}" >> .env
//               echo "SERVICE_PORT=8080" >> .env
//               echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
//             }
//           else
//             echo "AWS CLI not found on Jenkins server"
//             echo "Creating comprehensive fallback .env file..."
//             echo "# Fallback environment configuration" > .env
//             echo "ENVIRONMENT=${envName}" >> .env
//             echo "SERVICE_PORT=8080" >> .env
//             echo "JAVA_OPTS=-Xmx512m -Xms256m" >> .env
//             echo "AWS_REGION=${awsRegion}" >> .env
//             echo "APPLICATION_NAME=${applicationName}" >> .env
//             echo "Log level set to INFO for ${envName} environment" >> .env
//           fi
          
//           echo "Environment file contents:"
//           cat .env || echo "No .env file created"
//         """
//       }
//       stage('login to ecr') {
//         sh("aws ecr get-login-password --region ${awsRegion}  | docker login --username AWS --password-stdin ${ecrUrl}")
//       }
//       stage('Build Docker Image') {
//         sh """
//           echo "=== Docker Build Debug Info ==="
//           echo "Service Name: ${serviceName}"
//           echo "ECR URL: ${ecrUrl}"
//           echo "Image Tag: ${imageTag}"
//           echo "Dockerfile: ${dockerfile}"
//           echo "Available JAR files in helm/:"
//           ls -la helm/*.jar || echo "No JAR files found"
          
//           echo "Preparing Docker build context..."
//           cp helm/*.jar dockerfile/ || echo "Warning: No JAR files copied"
          
//           echo "Files in dockerfile directory:"
//           ls -la dockerfile/
          
//           echo "Building Docker image..."
//           docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} dockerfile/
          
//           echo "=== Build Complete ==="
//         """
//       }
//       stage('Push Docker Image To ECR') {
//         sh("docker push ${ecrUrl}/${serviceName}:${imageTag}")
//       }
//       stage('Clean docker images') {
//         sh("docker rmi -f ${ecrUrl}/${serviceName}:${imageTag} || :")
//       }
//       stage ("Deploy ${serviceName} to ${EnvName} Environment") {
//         sh ("cd slashtec/${helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
//         sh ("cd slashtec/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
//       }

//       // stage ("Deploy preprod-solo-queue to ${EnvName} Environment") {
//       //   build job: 'preprod-solo-queue', wait: true
//       // }
//       // stage ("Deploy preprod-solo-crons to ${EnvName} Environment") {
//       //   build job: 'preprod-solo-crons', wait: true
//       // }
//     } catch (Exception e) {
//       currentBuild.result = 'FAILURE'
//       throw e
//     } finally {
//       notifyBuild(currentBuild.result ?: 'SUCCESS', branchName)
//     }
// }