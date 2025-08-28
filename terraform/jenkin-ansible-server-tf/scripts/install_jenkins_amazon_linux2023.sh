#!/bin/bash
## This script is only for Amazon Linux 2023 Kernel-6.12(hvm)
exec > /var/log/user-data.log 2>&1

yum update -y
yum install -y java-17-amazon-corretto

wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins

systemctl enable jenkins
systemctl start jenkins