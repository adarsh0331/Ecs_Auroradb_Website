pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging'], description: 'Select environment to deploy')
    }

    environment {
        AWS_REGION      = 'us-east-1'
        AWS_CREDENTIALS = credentials('aws-jenkins-creds')
        ECR_REPO        = '141559732042.dkr.ecr.us-east-1.amazonaws.com/mywebsite'
        // IMAGE_TAG will be set after checkout (contains BUILD_NUMBER + git short sha)
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'https://github.com/Jithendarramagiri1998/ecs-aurora-website.git'
                script {
                    // capture short git sha and set a unique image tag
                    def gitShort = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "v${env.BUILD_NUMBER}-${gitShort}"
                    echo "Using IMAGE_TAG = ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                script {
                    def terraformRoot = "${env.WORKSPACE}/terraform"
                    def backendPath   = "${terraformRoot}/global/backend"
                    def envPath       = "${terraformRoot}/envs/${params.ENV}"

                    dir(envPath) {
                        sh '''
                        set -eux
                        if ! aws s3api head-bucket --bucket my-terraform-states-1234 2>/dev/null; then
                            echo "🚀 Creating backend S3 & DynamoDB..."
                            cd ../../global/backend
                            terraform init -input=false
                            terraform apply -auto-approve
                            cd -
                        else
                            echo "✅ Backend S3 bucket already exists."
                        fi

                        terraform init \
                          -backend-config="bucket=my-terraform-states-1234" \
                          -backend-config="key=${ENV}/terraform.tfstate" \
                          -backend-config="region=us-east-1" \
                          -backend-config="dynamodb_table=terraform-locks" \
                          -input=false

                        terraform validate
                        terraform workspace select ${ENV} || terraform workspace new ${ENV}
                        '''
                    }
                }
            }
        }

     stage('Terraform Plan & Apply') {
    steps {
        dir("terraform/envs/${params.ENV}") {
            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'aws-jenkins'
            ]]) {
                sh 'pwd'
                sh 'ls -la'
                sh """
                terraform init
                terraform plan -var-file='${WORKSPACE}/terraform/envs/${params.ENV}/${params.ENV}.tfvars' -out=tfplan
                terraform apply -auto-approve tfplan
                """
            }
        }
    }
}
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔧 Building Docker image with app code..."
                    sh '''
                    set -eux
                    cd app
                    echo "📁 Checking files inside app/"
                    ls -la
                    echo "🐳 Building Docker image..."
                    docker build --no-cache -t ${ECR_REPO}:${IMAGE_TAG} .
                    echo "✅ Docker image built successfully: ${ECR_REPO}:${IMAGE_TAG}"
                    '''
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    sh '''
                    set -eux
                    echo "🔐 Logging in to Amazon ECR..."
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

                    # ensure repo exists (idempotent)
                    REPO_NAME=$(basename "${ECR_REPO}")
                    if ! aws ecr describe-repositories --repository-names "${REPO_NAME}" --region ${AWS_REGION} >/dev/null 2>&1; then
                        aws ecr create-repository --repository-name "${REPO_NAME}" --region ${AWS_REGION} || true
                    fi

                    echo "🚀 Pushing Docker image to ECR..."
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to ECS (safe rolling with immutable digest)') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    sh '''
                    set -eux
                    echo "🚀 Deploy: building immutable image reference and updating ECS..."

                    REPO_URI="${ECR_REPO}"                        # e.g. 141559.../mywebsite
                    REPO_NAME=$(basename "${REPO_URI}")          # mywebsite
                    IMAGE_TAG="${IMAGE_TAG}"                     # v123-abcd

                    # Wait for ECR image to be available
                    echo "🔎 Waiting for image ${REPO_NAME}:${IMAGE_TAG} in ECR..."
                    for i in 1 2 3 4 5 6; do
                      aws ecr describe-images --repository-name "${REPO_NAME}" --image-ids imageTag="${IMAGE_TAG}" --region ${AWS_REGION} && break || sleep 2
                    done

                    # Get the image digest (sha256:...)
                    IMAGE_DIGEST=$(aws ecr describe-images \
                      --repository-name "${REPO_NAME}" \
                      --image-ids imageTag="${IMAGE_TAG}" \
                      --query 'imageDetails[0].imageDigest' --output text --region ${AWS_REGION})

                    if [ -z "${IMAGE_DIGEST}" ] || [ "${IMAGE_DIGEST}" = "None" ]; then
                      echo "ERROR: Could not find image digest in ECR for ${REPO_NAME}:${IMAGE_TAG}"
                      exit 1
                    fi

                    IMMUTABLE_IMAGE="${REPO_URI}@${IMAGE_DIGEST}"
                    echo "✅ Using immutable image: ${IMMUTABLE_IMAGE}"

                    # Task family name (should match your existing family)
                    TASK_FAMILY="${ENV}-app-task"

                    # Fetch current task definition JSON for the family (taskDefinition object)
                    echo "📦 Fetching current task definition for family ${TASK_FAMILY}..."
                    CURRENT_TASK_JSON=$(aws ecs describe-task-definition --task-definition "${TASK_FAMILY}" --region ${AWS_REGION} --query 'taskDefinition' --output json)

                    if [ -z "${CURRENT_TASK_JSON}" ] || [ "${CURRENT_TASK_JSON}" = "null" ]; then
                        echo "ERROR: Could not fetch current task definition for ${TASK_FAMILY}"
                        exit 1
                    fi

                    # Build new task definition JSON - remove fields not allowed during register, replace image with immutable image
                    echo "${CURRENT_TASK_JSON}" \
                      | jq --arg img "${IMMUTABLE_IMAGE}" 'del(.status, .revision, .taskDefinitionArn, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy) |
                        .containerDefinitions = (.containerDefinitions | map(.image = $img))' \
                      > new-task-def.json

                    echo "📝 Registering new task definition..."
                    REGISTER_OUT=$(aws ecs register-task-definition --cli-input-json file://new-task-def.json --region ${AWS_REGION})
                    NEW_TASK_DEF_ARN=$(echo "${REGISTER_OUT}" | jq -r '.taskDefinition.taskDefinitionArn')
                    echo "✅ Registered: ${NEW_TASK_DEF_ARN}"

                    echo "🚀 Updating ECS service ${ENV}-ecs-service in cluster ${ENV}-ecs-cluster..."
                    aws ecs update-service --cluster ${ENV}-ecs-cluster --service ${ENV}-ecs-service --task-definition "${NEW_TASK_DEF_ARN}" --region ${AWS_REGION}

                    echo "⏳ Waiting for service to stabilize..."
                    aws ecs wait services-stable --cluster ${ENV}-ecs-cluster --services ${ENV}-ecs-service --region ${AWS_REGION}
                    echo "🎉 Deployment finished and stable."
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "✅ Deployment completed for ${params.ENV} environment!"
                    echo "🌐 Check website URL after Route53 setup: https://${params.ENV}.yourdomain.com"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 ${params.ENV} deployment successful!"
            mail to: 'ramagirijithendar1998@gmail.com',
                 subject: "✅ Jenkins Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "The build succeeded!\nCheck details: ${env.BUILD_URL}"
        }
        failure {
            echo "❌ Deployment failed. Check Jenkins logs and CloudWatch for details."
            mail to: 'ramagirijithendar1998@gmail.com',
                 subject: "❌ Jenkins Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "The build failed.\nPlease check console output: ${env.BUILD_URL}"
        }
    }
}
