# Solar System MERN App & DevOps Showcase

![GitHub repo size](https://img.shields.io/github/repo-size/your-username/your-repo-name)
![GitHub top language](https://img.shields.io/github/languages/top/your-username/your-repo-name)
![GitHub last commit](https://img.shields.io/github/last-commit/your-username/your-repo-name)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A full-stack MERN (MongoDB, Express, React, Node.js) application that serves as the centerpiece for a complete, production-grade DevOps project on AWS EKS. This repository contains the application source code. The entire cloud infrastructure and deployment configuration are managed in a separate [GitOps repository](https://github.com/your-username/your-gitops-repo).

This project demonstrates a holistic approach to modern cloud-native development, integrating best practices across Infrastructure as Code, CI/CD, GitOps, security, and observability.

**Live Demo URL:** [solarapp.sourabhbiswasdevops.cloud](https://solarapp.sourabhbiswasdevops.cloud)

![Solar System App Screenshot](https://your-image-hosting-service.com/solar-system-screenshot.png) 
<!-- TODO: Add a screenshot of your live application -->

## 🚀 Project Architecture Overview

This project is built on a modern, decoupled CI/CD architecture using a push-then-pull model.

![Architecture Diagram](https://your-image-hosting-service.com/architecture-diagram.png)
<!-- TODO: Add the architecture diagram you created -->

1.  **Infrastructure as Code (IaC):**
    *   **Terraform** is used to provision all AWS resources, including the VPC, EKS Cluster, and IAM Roles for Service Accounts (IRSA). This ensures the environment is reproducible, version-controlled, and can be torn down cleanly.

2.  **Continuous Integration (CI):**
    *   **Jenkins** automates the build and integration process.
    *   When code is pushed to this repository, a `Jenkinsfile` pipeline is triggered.
    *   The pipeline builds a new Docker image, tags it, and pushes it to a container registry (Docker Hub).
    *   Crucially, the pipeline then checks out the separate **GitOps repository** and programmatically updates the image tag in the environment's Helm values file before pushing the change.

3.  **Continuous Deployment (CD) with GitOps:**
    *   **Argo CD** is the GitOps engine, acting as the single source of truth for the cluster's state.
    *   It continuously monitors the **GitOps repository**.
    *   When it detects the new image tag pushed by Jenkins, it automatically syncs the changes to the EKS cluster, performing a zero-downtime rolling update of the application.

## ✨ Key Features & DevOps Showcase

This project isn't just a simple deployment; it's a demonstration of a complete, production-ready platform.

### ☸️ Kubernetes & Containerization
*   **Multi-Stage Dockerfile:** The application is containerized using an optimized, multi-stage build that produces a small and secure final image.
*   **Non-Root User:** The container runs as a non-root user to adhere to the principle of least privilege.
*   **GitOps with Argo CD:** Deploys all cluster components, including core services and the application itself, using the "App of Apps" pattern for centralized management.
*   **Helm:** All application manifests are packaged as a flexible and configurable Helm chart.

### 🔒 Security
*   **IRSA (IAM Roles for Service Accounts):** Pods are granted fine-grained AWS permissions without needing static credentials.
*   **External Secrets Operator (ESO):** MongoDB credentials are securely fetched from **AWS Secrets Manager** at runtime. No secrets are ever stored in Git or the Docker image.
*   **Network Security:** All public-facing traffic is routed through a single, shared **AWS Application Load Balancer (ALB)** with HTTPS enforced via **AWS Certificate Manager (ACM)**.

### 📈 Observability (The O11y Stack)
*   **Whitebox Monitoring:** The Node.js backend exposes a `/metrics` endpoint with custom metrics (using `prom-client`), which are scraped by **Prometheus** via a `ServiceMonitor`.
*   **Blackbox Monitoring:** The **Blackbox Exporter** is configured to probe the live website URLs from an external perspective, measuring uptime, latency, and SSL certificate validity.
*   **Visualization:** **Grafana** provides a single pane of glass with pre-built dashboards for cluster health and custom dashboards for application-specific and blackbox metrics.
*   **Alerting:** **Alertmanager** is configured with `PrometheusRule` manifests to fire alerts on critical conditions, such as high application error rates.

## 🛠️ Application Details

### Backend (Node.js / Express)
*   Connects to a Mongo Atlas database for planet data.
*   Serves a simple REST API.
*   Exposes health check endpoints (`/live`, `/ready`) used by Kubernetes probes.
*   Exposes a `/metrics` endpoint for Prometheus scraping.

### Frontend (React)
*   A simple single-page application that fetches and displays data from the backend.
*   The build is served statically by the Express server.

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

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.