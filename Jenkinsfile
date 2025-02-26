// Jenkins Pipeline for Automated Disaster Recovery (DR) on AWS

pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1' // Set AWS region
    }
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo 'Initializing DR Setup...'
                }
            }
        }

        stage('Setup S3 Backup Management') {
            steps {
                script {
                    echo 'Applying S3 Lifecycle Policies to auto-delete old backups...'
                    sh '''
                    aws s3api put-bucket-lifecycle-configuration \
                        --bucket my-dr-backups \
                        --lifecycle-configuration file://s3-lifecycle-policy.json
                    '''
                }
            }
        }

        stage('Manage EC2 Instances') {
            steps {
                script {
                    echo 'Ensuring DR EC2 instances use Spot Instances & Auto Start/Stop via Lambda...'
                    sh '''
                    aws lambda invoke --function-name StartStopDRInstances response.json
                    '''
                }
            }
        }

        stage('Database DR Setup') {
            steps {
                script {
                    echo 'Automating RDS backup & cross-region replication...'
                    sh '''
                    aws rds create-db-snapshot --db-instance-identifier my-primary-db --db-snapshot-identifier my-dr-snapshot
                    aws rds copy-db-snapshot --source-db-snapshot-identifier my-dr-snapshot --target-db-snapshot-identifier my-dr-snapshot-copy --destination-region us-west-2
                    '''
                }
            }
        }

        stage('Failover Configuration') {
            steps {
                script {
                    echo 'Setting up Route 53 Health Checks & Failover Routing...'
                    sh '''
                    aws route53 change-resource-record-sets --hosted-zone-id Z12345 --change-batch file://route53-failover.json
                    '''
                }
            }
        }

        stage('Monitoring & Alerts') {
            steps {
                script {
                    echo 'Configuring CloudWatch Alarms & SNS Alerts...'
                    sh '''
                    aws cloudwatch put-metric-alarm --alarm-name DR-Failover-Alarm --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=i-1234567890abcdef0 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:123456789012:MySNSTopic
                    '''
                }
            }
        }
    }
}
