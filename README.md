# Solar-system-devops-project

Solar System Devops project with CI Jenkins &amp; CD ArgoCD. Deployment on EKS using Helm. IaC using Terraform. Monitoring using Promethes. Grafana. Observibitly &amp; logs uisng EFK stack.

## About Project: - A simple HTML + MongoDB + NodeJS project to display Solar System and it's planets.

1. Local Development, Containerization & Push to Docker Hub
    - Tools: Node.js, MongoDB, Html, Docker 
    - Actions: Local run, Dockerfile creation, image push to registry
2. CI/CD Pipeline Setup
    - Tools: Jenkins (on Spot EC2), AWS Secrets Manager, SonarQube, Slack, S3
    - Actions: Jenkinsfile with build/test/quality stages, Slack alerts, test report upload
3. Environment Management & GitOps
    - Tools: Git (Dev/Stage/Prod branches), ArgoCD
    - Actions: Continuous deployment for Dev/Stage, delivery for Prod with approval
4. Kubernetes Deployment
    - Tools: Helm, ArgoCD
    - Actions: Helm charts with separate values files, ArgoCD sync waves
5. Infrastructure as Code
    - Tools: Terraform, Ansible, AWS (EKS, EC2, S3, DynamoDB)
    - Actions: Provision EKS clusters and Jenkins EC2, state locking, VM config
6. Observability & Monitoring
    - Tools: Prometheus, Alertmanager, Grafana, EFK stack
    - Actions: Performance metrics, dashboards, centralized logging
7. Security & Governance
    - Tools: AWS Secrets Manager, IAM, TLS/HTTPS
    - Actions: Secrets management, RBAC, secure service exposure



