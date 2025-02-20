pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key') // Store in Jenkins credentials
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/vibhuti2023/terraform-dr.git'
            }
        }

        stage('Install Terraform') {
            steps {
                sh '''
                curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
                sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                sudo apt-get update && sudo apt-get install -y terraform
                terraform --version
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Cleanup') {
            steps {
                sh 'terraform destroy -auto-approve'
            }
        }
    }
}
