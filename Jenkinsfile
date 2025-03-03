pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    credentialsId: '38577a24-edb9-4570-85a6-75dfbde1a695', 
                    url: 'https://github.com/vibhuti2023/terraform-dr3.git'
            }
        }

        stage('Initialize Terraform') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Validate Terraform Code') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Plan Infrastructure Changes') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Apply Changes') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Display Outputs') {
            steps {
                sh 'terraform output'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*.tfstate', fingerprint: true
        }
    }
}

