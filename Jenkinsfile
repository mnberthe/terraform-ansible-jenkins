pipeline {
  agent any
  environment {
    TF_IN_AUTOMATION = 'true'
    TF_CLI_CONFIG_FILE = credentials('tf-creds')
    AWS_ACCESS_KEY_ID= credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }
  stages {
    stage('Init') {
        steps { 
            sh 'ls'
            sh 'TF_IN_AUTOMATION=true'
            sh 'terraform init -no-color'

        }
    }
    stage('Plan') {
        steps {
            sh 'TF_IN_AUTOMATION=true'
            sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
    
    stage('Validate Apply'){
      when {
        beforeInput true
        branch "dev"
      }
      input {
        message "Do you want to apply this plan ? "
        ok "Apply this plan"
      }

      steps {
        echo 'Apply Accepted'
      }
    }

    stage('Apply'){
        steps {
             sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }

    stage('Inventory') {
      steps {
        sh '''printf \\
          "\\n$(terraform output -json instance_ips | jq -r \'.[]\')" \\
          >> aws_hosts'''
      }
    }

    stage('Ec2 wait'){
        steps {
            sh '''aws ec2 wait instance-status-ok \\
              --instance-ids $(terraform output -json instance_ids | jq -r \'.[]\') \\
              --region eu-west-3
              '''
        }
    }

    stage('Validate Ansible'){
      when {
        beforeInput true
        branch "dev"
      }
      input {
        message "Do you want to run Ansible ? "
        ok "Run Ansible."
      }

      steps {
        echo 'Ansible Accepted'
      }
    }

    stage('Ansible'){
        steps {
            ansiblePlaybook(credentialsId: 'ec2-key	', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
        }
    }

    stage('Validate Destroy'){
      input {
        message "Do you destroy all the things ? "
        ok "Destroy"
      }

      steps {
        echo 'Destroy Accepted'
      }
    }

    stage('Destroy'){
        steps {
             sh 'terraform destroy -auto-approve  -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
  }

  post{
    success {
      echo 'Success!'
    }
    failure {
      sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
    }
    aborted{
        sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
    }
  }
}