pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "abhinaprakash783/amazon-project-devops"
        DOCKER_HUB_CREDENTIALS = "docker-hub-creds-v7"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'master', url: 'https://github.com/abhinav12222363/Amazon-clone.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def tag = "v${env.BUILD_NUMBER}"
                    def imageTag = "${DOCKER_IMAGE}:${tag}"
                    env.IMAGE_TAG = imageTag
                    bat "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}",
                                                      usernameVariable: 'DOCKER_USERNAME',
                                                      passwordVariable: 'DOCKER_PASSWORD')]) {
                        bat "docker login -u %DOCKER_USERNAME% -p %DOCKER_PASSWORD%"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    bat "docker push ${env.IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
