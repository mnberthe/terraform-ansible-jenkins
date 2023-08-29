#  Terraform and Ansible Traning

In this course we will learn how to use terraform and ansible and automate deployment process with jenkins.

Some of the goals of this sample:

 - Create an account on terraform cloud to store state for main Terraform code.
 - Install Jenkins using ansible **playbook** 
 - Automate Terraform to create EC2 with Jenkins pipeline.
 - Automatically generate **Inventory** for Ansible from Terraform output.
 - Jenkins executes Ansible playbook to install **Grafana** and **Prometheus**
 
 ## Terraform
 
 - Install terraform
 - Create an account on terraform cloud
 -  Login to terraform cloud cloud using the **token** 
 
## Aws Cli 
Install aws-cli and export aws **credentials** 

## Ansible 
Install ansible and configure it 

 ***sudo vim /etc/ansible/hosts***
```
[hosts] 
localhost 
[hosts:vars] 
ansible_connection=local 
ansible_python_interpreter=/usr/bin/python3
```
And then ***sudo vim /etc/ansible/ansible.cfg***
```
host_key_checking = False
```

## Jenkins
Install jenkins using ansible playbook 
```
ansible-playbook -i aws_hosts playbooks/jenkins.yml
```
### Jenkins plugins to install

 - Ansible plugin
 - Pipeline Aws step

### Jenkins credentials

Inside Jenkins server generate ssh keys
```
ssh-keygen -t rsa 
```
Put the public key in keys folders, the private key will be added to jenkins credentials. 

#### Git(Git ssh key)
-   Put public key in github **Deploy keys section**  in concern repo
-   Add credential **kind username with private key** in jenkins copy the previous private key

#### Ansible(EC2 SSH key)
Add Jenkins credential **kind username with private key** and add the previous private key

#### Terraform (token)

 - Copy the content of this command
 -  ```cat /home/vagrant/.terraform.d/credentials.tfrc.json```
 - Add Jenkins credential kind **secret file** with the content 
 - it will be used as **TF_CLI_CONFIG_FILE** value in jenkins pipeline
#### Aws (secret key)
Add jenkins credential of kind **secret text** for **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY**
 It will be used in pipeline like this 
```
environment { AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID') 
AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
}
```
