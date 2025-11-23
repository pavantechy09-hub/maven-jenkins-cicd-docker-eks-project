pipeline {
    agent any

    environment {
        // For public repo, do NOT hardcode AWS account here. Prefer injecting these
        // via Jenkins Global Credentials / Environment variables or using the instance role.
        AWS_ACCOUNT_ID = ''
        AWS_ECR_REPO_NAME = 'demo'
        AWS_DEFAULT_REGION = 'us-east-2'
        // REPOSITORY_URI can be provided directly or derived from AWS_ACCOUNT_ID
        REPOSITORY_URI = ''
        GIT_REPO_NAME = "maven-jenkins-cicd-docker-eks-project"
        # Provide the repo URL (https://github.com/your-org/your-repo.git) in the job environment
        GIT_REPO_URL = ''
        # Configure Git committer identity via environment variables or Jenkins credentials
        GIT_EMAIL = ''
        GIT_USER_NAME = ''
        YAML_FILE = "deploy_svc.yml"
    }

    stages {
        stage('Clean') {
            steps { cleanWs() }
        }

        stage('Validate env') {
            steps {
                script {
                    // Determine REPOSITORY_URI if not explicitly set
                    if (!env.REPOSITORY_URI?.trim()) {
                        if (!env.AWS_ACCOUNT_ID?.trim()) {
                            error("REPOSITORY_URI or AWS_ACCOUNT_ID must be provided in the job environment")
                        } else {
                            env.REPOSITORY_URI = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com"
                            echo "Derived REPOSITORY_URI=${env.REPOSITORY_URI}"
                        }
                    } else {
                        echo "Using REPOSITORY_URI=${env.REPOSITORY_URI}"
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                // adjust branch in job configuration if needed
                script {
                    if (!env.GIT_REPO_URL?.trim()) {
                        error("GIT_REPO_URL must be provided in the job environment (e.g. https://github.com/your-org/your-repo.git)")
                    }
                    git branch: 'master', url: env.GIT_REPO_URL
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B -DskipTests=false clean package'
            }
            post {
                always { junit '**/target/surefire-reports/*.xml' }
                success { archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                    sh 'docker tag ${AWS_ECR_REPO_NAME}:latest ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                    // also tag latest for easy manifest references
                    sh 'docker tag ${AWS_ECR_REPO_NAME}:latest ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:latest'
                    sh 'docker push ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                    sh 'docker push ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:latest'
                }
            }
        }

        stage('Update manifest & Push') {
            steps {
                dir('Kubernetes-Manifests-file') {
                    withCredentials([string(credentialsId: 'my-git-pattoken', variable: 'git_token')]) {
                        sh '''
                            if (env.GIT_EMAIL?.trim()) { git config user.email "${GIT_EMAIL}" }
                            if (env.GIT_USER_NAME?.trim()) { git config user.name "${GIT_USER_NAME}" }
                            sed -i "s#image:.*#image: ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}#g" ${YAML_FILE}
                            git add ${YAML_FILE}
                            git commit -m "Update ${AWS_ECR_REPO_NAME} image to ${BUILD_NUMBER}" || true
                            # push using the provided repo URL and token
                            repo_no_proto=$(echo ${GIT_REPO_URL} | sed -e 's#https://##' -e 's#http://##')
                            git push https://${git_token}@${repo_no_proto} HEAD:master || true
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS (manual)') {
            steps {
                echo 'Deployment to EKS is performed by applying Kubernetes manifests from the repository (or by ArgoCD). Ensure Jenkins can run kubectl with proper kubeconfig or use ArgoCD for GitOps.'
            }
        }
    }
}
