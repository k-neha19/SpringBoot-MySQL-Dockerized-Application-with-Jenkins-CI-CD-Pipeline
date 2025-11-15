pipeline {
    agent any

    tools {
        maven 'maven'
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Select the deployment environment')
        choice(name: 'ACTION', choices: ['deploy', 'remove'], description: 'Am selecting for the action')
    }

    environment {
        DOCKERHUB_USERNAME = 'sakit333'
        DOCKER_IMAGE = "${env.JOB_NAME}"
        DOCKER_COMPOSE_FILE = "docker-compose.yml"
    }

    stages {
        stage('To Build the Jar file for DEV'){
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'dev' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps{
                sh 'mvn clean package -Dskiptests'
            }
        }
        stage('Deploy Containers to Dev Env') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'dev' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                echo "Deploying Docker containers using Compose..."
                sh "sudo docker-compose -f ${DOCKER_COMPOSE_FILE} up -d --build"
            }
        }
        stage('Remove Containers from Dev Env') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'dev' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo "Stopping and removing containers and volumes..."
                sh "sudo docker-compose -f ${DOCKER_COMPOSE_FILE} down -v"
            }
        }
        stage('Cleanup Old Images') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'dev' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo "Cleaning up old Docker images..."
                sh "sudo docker image prune -af"
            }
        }
        stage('Remove Jar Build') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'dev' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo 'Removing Target Dir from the maven project'
                sh 'mvn clean'
            }
        }
        // Prodction stages
        stage('To Build the Jar file for PROD'){
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps{
                sh 'mvn clean package -Dskiptests'
            }
        }
        stage('Build the Docker images') {
            when{
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }        
            }
            steps {
                echo "Build the Docker image....."
                sh 'sudo docker build -t ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest .'
            }
        }
        stage('Login to DockerHub') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                echo "Logging in to DockerHub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    sh 'echo "$DOCKERHUB_PASS" | sudo docker login -u "$DOCKERHUB_USER" --password-stdin'
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                echo "Pushing Docker image to DockerHub..."
                sh '''
                    sudo docker push ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest
                    sudo docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest || true
                '''
            }
        }
        stage('DockerHub account logout') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo "Removing Docker cred..."
                sh '''
                    sudo docker logout
                '''
            }
        }
        stage('Cleanup Local Docker Images') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo "Removing local Docker images..."
                sh '''
                    sudo docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest || true
                    sudo docker system prune -af
                '''
            }
        }
        stage('Remove target after Prod is completed') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo 'Removing Target Dir from the maven project'
                sh 'mvn clean'
            }
        }
    }
    post {
        success {
            echo "project is success"
        }
        failure {
            echo "project is failure"
        }
    }
}