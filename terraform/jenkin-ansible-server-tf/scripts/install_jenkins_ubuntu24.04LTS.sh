#!/bin/bash
exec > /var/log/user-data.log 2>&1

echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

echo "=== Checking for Java installation ==="
if ! command -v java &> /dev/null; then
    echo "Java not found — installing OpenJDK 21..."
    apt-get install -y openjdk-21-jdk
else
    echo "Java is already installed: $(java -version 2>&1 | head -n 1)"
fi

echo "=== Adding Jenkins repository and key ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Installing Jenkins ==="

apt-get install -y jenkins

echo "=== Enabling and starting Jenkins service ==="
systemctl enable jenkins
systemctl start jenkins

echo "=== Jenkins installation complete ==="
systemctl status jenkins --no-pager

echo "=== Updating system packages after jenkins installation ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing Gitleaks ==="
apt-get install -y gitleaks
echo "Gitleaks version: $(gitleaks --version)"

echo "=== Installing Docker ==="
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
usermod -aG docker jenkins
systemctl start docker
systemctl enable docker
systemctl restart jenkins
echo "Docker installation completed."
echo "Docker version: $(docker --version)"

echo "=== SonarQube container setup ==="
docker run -d \
  --name sonarqube \
  --restart always \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:lts-community
echo "SonarQube container is running on port 9000."
echo "SonarQube container status: $(docker ps -f name=sonarqube --format '{{.Status}}')"
echo "SonarQube logs:"
docker logs sonarqube --tail 10
docker ps

echo "=== Install Trivy ==="
apt-get install -y trivy
echo "Trivy version: $(trivy --version)"
echo "=== Script execution completed ==="
echo "=== Rebooting EC2 instance to apply group memberships ==="
reboot
