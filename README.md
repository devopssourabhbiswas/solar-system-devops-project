# Solar System MERN App & DevOps Showcase

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-AWS%20EKS-orange)
![IaC](https://img.shields.io/badge/IaC-Terraform-darkgreen)
![CI/CD](https://img.shields.io/badge/CD-Argo%20CD-blue)
![Observability](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-yellow)

A **cloud-native MERN (MongoDB, Express, React, Node.js)** production-grade application designed to demonstrate end‑to‑end **DevOps, GitOps, and Cloud Engineering excellence** on **Amazon EKS (Elastic Kubernetes Service)**.
This project showcases a *complete production‑grade platform* integrating **Infrastructure as Code (IaC)**, secure **CI/CD automation**, **GitOps deployment workflows**, and a **comprehensive observability stack**.

The Kubernetes deployment configuration are managed in a separate [GitOps repository](https://github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo).

- **Demo Video:** [YouTube Demo](https://your-youtube-demo-link) *(to be updated once available)*

## 🧭 High-Level Architecture

This solution is designed around automation, security, scalability, and deep insight.
[Solar System App Screenshot](https://github.com/devopssourabhbiswas/solar-system-devops-project/blob/main/project-demo-screenshots/solar-project-archieturerual-diagram.png)


![Solar System App Screenshot](https://github.com/devopssourabhbiswas/solar-system-devops-project/blob/main/project-demo-screenshots/solar-project-prodss.png) 
<!-- TODO: Add a screenshot of your live application -->

### 🧱 Core Components

| Layer | Component | Purpose |
|:--|:--|:--|
| **Cloud** | AWS EKS | Managed Kubernetes Control Plane |
| **IaC** | Terraform | Declaratively provisions AWS VPC, EKS, IAM roles (IRSA) |
| **CI** | Jenkins | Builds, tests, and packages app into Docker images |
| **CD (GitOps)** | Argo CD | Pull‑based continuous delivery to EKS |
| **App Configuration** | Helm | Helm charts define all Kubernetes application manifests |
| **Secrets Management** | AWS Secrets Manager + External Secrets Operator | Runtime secret retrieval (no secrets in Git) |
| **Ingress** | AWS ALB Controller + ACM | Centralized HTTPS routing and SSL termination |
| **Monitoring** | Prometheus, Grafana, Alertmanager, Blackbox Exporter | Full observability with declarative alerting |

---
## 🧩 System Design Philosophy

### 1. Automated CI/CD
- **Jenkins** drives the CI pipeline, triggered on every commit.  
- A **multi‑stage Dockerfile** builds a lightweight, secure Node.js container.  
- Jenkins updates the GitOps repository after pushing the new image tag, enabling **pull‑based Continuous Deployment** through Argo CD.

### 2. GitOps with Argo CD
Traditional push-based deployments grant external system credentials to clusters — increasing risk.  
In contrast, GitOps provides:
- **Single Source of Truth:** Cluster state is always driven by Git.
- **Security:** Jenkins modifies Git, not kube-apiserver directly.
- **App of Apps Pattern:** Argo CD manages itself, its dependencies, and all applications declaratively.

**Flow:**

```
Developer Push → Jenkins → GitOps Repo (image tag update) → Argo CD Sync → EKS Deploy
```
### 3. Terraform for IaC
Terraform codifies provisioning of:
- **VPC** (multi-AZ private + public subnets)  
- **EKS Cluster** and worker nodegroups  
- **IAM Roles for Service Accounts (IRSA)** for pod‑level authorization  
- **S3 remote backend** for state locking
- **EBI CSI driver** allows the driver to manage EBS volumes securely on AWS
- **Storage Class** creates a gp3 storage class for cost‑optimized persistent storage layer, high‑throughput and high IOPS, as compared to EKS classic use of gp2 EBS volume.

Everything is reproducible and versioned.

### 4. Advanced Networking
- A **single, shared AWS Application Load Balancer (ALB)** handles routing for all HTTP/S workloads.
- Implements **host‑based routing**, **SSL termination** via **AWS Certificate Manager (ACM)**, and **WAF** support for edge protection.
- Using `target-type: ip`, the ALB connects **directly to pods**, bypassing `kube-proxy` for better performance and source IP preservation.


### 4. Secure Secrets Handling with ESO
Secrets are **never committed to Git**.  
- ESO retrieves credentials from **AWS Secrets Manager** dynamically.  
- Permissions are scoped to the ESO ServiceAccount using IRSA.  
- Secret rotation can occur transparently to running pods.

### 4. Observability Stack

# 📈 Observability Examples
![Grafana Dashboard](https://your-image-hosting-service.com/architecture-diagram.png)

Prometheus & Grafana showing API latency and uptime metrics.

### 📊 Comprehensive Whitebox Monitoring
- The **Kube‑Prometheus‑Stack** (Prometheus, Alertmanager, Grafana, etc.) continuously scrapes:
  - Cluster components (nodes, kubelet, API server, etcd)
  - Custom MERN app metrics exposed via `/metrics` endpoint from `prom-client`
- Provides “golden signals” — latency, error rate, throughput, and saturation.

### 🌍 Complete Blackbox Monitoring
- The **Blackbox Exporter** actively probes:
  - Public URLs: `solarapp.sourabhbiswasdevops.cloud` and `dev.sourabhbiswasdevops.cloud`
  - User‑facing performance (uptime, latency, SSL validity, DNS resolution time)
- Offers real insights into *what end users experience*.

### 🚨 Actionable Alerting
- **PrometheusRule** manifests define alert triggers declaratively (CPU, memory, error rate thresholds).  
- **Alertmanager** routes alerts to defined channels (Slack/email integrations possible) for immediate notification of critical conditions.

### 📈 Powerful Visualization
- **Grafana** runs with pre‑built dashboards for:
  - Cluster components and workloads  
  - Application metrics  
  - Blackbox performance probes  
- Also imports **popular community dashboards**, giving instant insights with no manual setup.

### 💪 Resilient Application
- The MERN app includes:
  - **Liveness and Readiness Probes** for self‑healing and graceful rollouts.
  - **Reactive, mobile‑friendly frontend** built with React.
  - Optimized **Node.js backend**, instrumented for observability.
- Delivers both developer ease and operational stability — the hallmark of a production‑ready service.

---

## ⚙️ CI/CD Workflow Detailed
# 📈 CI Jenkins pipeline Examples
![Jenkins pipeline](https://your-image-hosting-service.com/architecture-diagram.png)


1. **Code Commit → Jenkins Trigger:**  
   Jenkins pipeline (`Jenkinsfile`) runs on every change to the app repository.

2. **Build & Push Image:**  
   - Builds Docker image using a multi‑stage `Dockerfile`  
   - Tags image with current Git commit hash  
   - Pushes to **Docker Hub**

3. **GitOps Repo Update:**  
   - Jenkins checks out the **GitOps repo**  
   - Updates Helm `values-dev.yaml` with new image tag  
   - Commits and opens a Pull Request for review and promotion  
   - Upon merge, **Argo CD** detects the change

4. **Argo CD Sync:**  
   - Automatically pulls new configuration from Git  
   - Performs **zero‑downtime rolling updates** in EKS

---

## ☸️ Application Overview

### Backend — Node.js / Express
- REST API serving **planetary data** from **MongoDB Atlas**  
- Health and readiness probes: `/live`, `/ready`  
- `/metrics` endpoint exposes Prometheus-compatible values.

### Frontend — React
- Single Page Application for browsing solar system data  
- Built with `create-react-app`, bundled and served by Express server.
- Uses API proxy configuration to communicate with backend.

---

## 🧰 Prerequisites

Ensure your environment satisfies the following requirements before deploying:

### 🧑‍💻 Local Development
| Dependency | Required Version | Installation Link |
|:--|:--|:--|
| **Node.js** | ≥ 18.x | [nodejs.org](https://nodejs.org) |
| **npm** | ≥ 9.x | Included with Node |
| **MongoDB** | Local or Atlas Cluster | [mongodb.com](https://www.mongodb.com) |
| **Docker** | ≥ 24.x | [docker.com](https://www.docker.com) |
| **Terraform** | ≥ 1.6.x | [terraform.io](https://developer.hashicorp.com/terraform) |
| **kubectl** | Matching EKS version | [kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/) |
| **AWS CLI** | v2.x configured | [aws.amazon.com/cli/](https://aws.amazon.com/cli/) |
| **Helm** | ≥ 3.x | [helm.sh](https://helm.sh/docs/intro/install/) |
| **Jenkins** | latest LTS | [jenkins.io](https://jenkins.io) |
| **Argo CD CLI** (optional) | latest | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io) |

### 🏗️ Cloud Requirements
- AWS Account with permissions for VPC, EKS, IAM, and ALB.
- EC2 t3a.large used in the worker nodes as a SPOT instance, **resulting 50% cost reduction**. 
- Domain hosted in Hostinger, Cloudflare, and GoDaddy. DNS record edit permission. 
- SSL via AWS Certificate Manager (ACM)  
- S3 bucket for Terraform remote backend storage  

---

## 🏃‍♂️ Running This Project Locally

While this project is designed for a full cloud deployment, you can run the application locally for development.

1.  **Prerequisites:**
    *   Node.js (v18+)
    *   npm
    *   MongoDB (A local instance or a free Mongo Atlas cluster)

2.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```

3.  **Create a `.env` file:**
    In the root of the project, create a `.env` file with your MongoDB connection details:
    ```
    MONGO_URI=your_mongodb_connection_uri
    MONGO_USERNAME=your_mongodb_username
    MONGO_PASSWORD=your_mongodb_password
    ```

4.  **Install dependencies and run:**
    ```bash
    # Install backend dependencies
    npm install

    # Start the server (runs on http://localhost:3000)
    npm start
    ```
    
# 🗃️ Repository Structure

```
PROJECT_ROOT
├── images
├── terraform
│   ├── EKS-cluster-tf
│   │   ├── create-backendS3
│   │   │   └── backend.tf
│   │   ├── bootstrap-argocd.yaml
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfvars
│   │   └── variable.tf
│   └── jenkin-ansible-server-tf
├── .dockerignore
├── .gitignore
├── .groovylintrc.json
├── Dockerfile
├── Jenkinsfile
├── LICENSE
├── README.md
├── app-controller.js
├── app-test.js
├── app.js
├── index.html
├── oas.json
├── package-lock.json
├── package.json
└── style.css
```



## 🧩 Common Challenges & Lessons Learned

Every production‑grade system encounters turbulence during its creation — that’s where the deep learning happens.  
Here are the key problems faced during this project and how they were systematically solved.

### 🔁 Dependency Cycles in Kubernetes
**Problem:**  
Certain components in the "App of Apps" setup depended on namespaces, CRDs, or controllers that weren’t created yet — leading to cyclic dependencies during Argo CD syncs.

**Resolution:**  
- Introduced **sync waves** in Argo CD (`argocd.argoproj.io/sync-wave` annotation).  
- Ensured foundational components (CRDs, operators) deploy before dependent apps.  
- Split large manifests into layered Helm charts — *infrastructure → base services → applications*.

---

### 🚧 503 Errors (Service Unavailable)
**Problem:**  
Intermittent 503 responses appeared on the ALB Ingress, especially after deployments or scaling events.

**Diagnosis:**  
- ALB health checks were failing during rolling updates.  
- Backend pods could receive traffic before readiness probes passed.  

**Resolution:**  
- Tuned **readiness probes** and **deployment update strategies** for graceful pod rollout.  
- Increased ALB health check grace period and enforced stable DNS propagation.  
- Ensured the target type was `ip` and `externalTrafficPolicy = Local` for direct, consistent routing.

---

### ❗ ProvisioningFailed Errors (Terraform & AWS Resources)
**Problem:**  
Terraform occasionally threw `ProvisioningFailed` or IAM‑related errors when spinning up EKS or ALB roles.

**Root Causes:**
- IAM trust policies were missing or mismatched between service accounts and their IRSA roles.  
- EKS nodegroups didn’t complete bootstrap before dependent Helm releases deployed.

**Resolution:**  
- Modularized Terraform structure with explicit **`depends_on` relationships**.  
- Added retry logic for EKS modules via `local-exec` provisioners.  
- Validated IAM policies using `terraform plan` in CI to prevent blind applies.

---

### 🔄 Argo CD Sync Issues
**Problem:**  
Apps stuck in “OutOfSync” or “Progressing” state, even though manifests looked correct.

**Diagnosis & Fix:**
- Cluster had CRDs missing (sync applied child apps before CRD provider).  
- Applied **synchronization waves**, **automated pruning**, and **self‑healing policies** in `Application` manifests.  
- Enabled “soft sync” retry hooks to auto‑recover without user intervention.

---

### 🧩 Helm Templating Errors
**Problem:**  
Templating inconsistencies across environments caused Helm to fail during sync (`nil pointer evaluating ...`).

**Resolution:**  
- Used `required` and `default` functions in Helm templates to ensure missing values didn’t break rendering.  
- Adopted `<env>.values.yaml` overrides — keeping `values-dev.yaml` and `values-prod.yaml` separate but minimal.  
- Added linting via `helm lint` in Jenkins CI before making GitOps commits.

---

### 📈 Complex Prometheus Configuration
**Problem:**  
Initial Prometheus setup failed to scrape custom `/metrics` from the MERN backend.

**Cause:**  
- Incorrect service selector labels in `ServiceMonitor`.  
- Missing service annotations for discovery.  
- Misaligned `prometheus.io/port` labels between app and scrape configuration.

**Resolution:**  
- Standardized labels across services (`app: solar-system-backend`).  
- Verified discovery using `kubectl port-forward` testing of targets.  
- Tuned retention policies, storage requests, and integrated alerting rules version‑controlled as CRDs.

---

### 💡 Key Takeaways
- **Automation needs orchestration:** Order of resource deployment matters as much as the definitions themselves.  
- **Visibility beats guesswork:** Prometheus and Grafana solved five root causes faster than any log tail.  
- **Git truly is the operating manual:** Once the GitOps repo stabilized, rollback and recovery became trivial.  
- **Errors ≠ Failure:** Each 503, failed sync, or Helm hiccup hardened the system’s reliability and your own DevOps reflexes.

The end result: a **resilient, observable, self‑correcting platform** that can sustain real‑world production demands.

---
## Backup and Recovery

### EBS Snapshots

- **Create Snapshot**:

  ```bash
  aws ec2 create-snapshot --volume-id vol-0bb1c79de4EXAMPLE --description " Prometheus-EBS"
  ```

- **Restore from Snapshot**:

  ```bash
  aws ec2 create-volume --snapshot-id snap-0bb1c79de4EXAMPLE --availability-zone ap-south1a
  ```

### Backup Strategies

- **Use Velero for Backup and Restore**:
  - **Install Velero**:

    ```bash
    velero install --provider aws --bucket <bucket-name> --secret-file <credentials-file> --backup-location-config region=<region>
    ```

- **Create a Backup**:

  ```bash
  velero backup create my-backup --include-namespaces solar-prod
  ```

---

---

## EKS Upgrades and Maintenance

### Upgrading EKS Clusters

- **Upgrade Control Plane**:
  - **Using Console**: Select your cluster and choose to upgrade.
  - **Using CLI**:

    ```bash
    aws eks update-cluster-version --name my-cluster --kubernetes-version 1.33
    ```

### Upgrading Node Groups

- **Update Node Groups**:

  ```bash
  aws eks update-nodegroup-version --cluster-name my-cluster --nodegroup-name my-node-group --release-version 1.33
  ```

### Regular Maintenance

- **Monitor Cluster Health**: Use Prometheus for monitoring and the Grafana Kubernetes dashboard for visualization. 
- **Check for Vulnerabilities**: Regularly scan images and clusters for security vulnerabilities.

---

# 🧑‍🚀 Author
Sourabh Biswas
**Cloud & DevOps Engineer**

[• LinkedIn](https://www.linkedin.com/in/sourabhbiswasdevops/)

Building scalable, secure, observable cloud platforms — one Solar System at a time. ☀️🚀

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
