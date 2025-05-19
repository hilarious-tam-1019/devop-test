# DevOps Test Infrastructure

This repository provides a modular, production-ready AWS infrastructure for a microservices-based application, managed with Terraform. It supports both development and production environments, and includes modules for VPC, EKS, RDS, CI/CD (CodePipeline, CodeBuild, CodeDeploy), and more. The codebase is designed for extensibility and automation, following best practices for infrastructure-as-code.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Modules & Components](#modules--components)
- [Service Configuration](#service-configuration)
- [Local Development](#local-development)

---

## Architecture Overview

**Dev Environment:**
1. **VPC Creation:**  
   A dedicated Virtual Private Cloud is provisioned to isolate all development resources, mimicking production networking on a smaller scale.
2. **EC2 Instance Launch:**  
   An EC2 instance is created within the VPC. This instance is pre-configured with:
   - **Docker & Docker Compose:** For running and managing containers locally.
   - **CodeDeploy Agent:** To test AWS CodeDeploy deployments as you would in production.
3. **IAM Role Assignment:**  
   The EC2 instance is assigned an IAM role with permissions to interact with AWS services (e.g., pulling images from ECR, accessing S3 buckets).
4. **Local Testing:**  
   Developers can SSH into the EC2 instance, run containers, and test deployment scripts in an environment similar to production, but isolated and cost-effective.

**Prod Environment:**
1. **VPC Creation:**  
   A production-grade VPC is set up with public and private subnets across multiple Availability Zones for high availability and security.
2. **EKS Cluster Provisioning:**  
   An Elastic Kubernetes Service (EKS) cluster is created within the VPC to orchestrate and manage containerized microservices.
   - **Node Group Setup:** EC2 instances are automatically managed as worker nodes for the cluster.
   - **IAM Roles:** Fine-grained permissions are set up for cluster operations and service accounts.
3. **RDS (PostgreSQL) Deployment:**  
   A managed PostgreSQL database is provisioned using Amazon RDS, with:
   - **Subnet Group:** Ensures the database is only accessible within private subnets.
   - **KMS Encryption:** All data at rest is encrypted using AWS Key Management Service.
   - **Secrets Manager:** Database credentials are securely stored and managed.
4. **CI/CD Pipeline Setup:**  
   A full continuous integration and deployment pipeline is established:
   - **CodePipeline:** Automates the flow from code commit to deployment.
   - **CodeBuild:** Builds and tests application code.
   - **CodeDeploy:** Handles deployment to EKS or EC2.
   - **ECR:** Stores Docker images built by CodeBuild.
   - **S3:** Stores build artifacts and deployment scripts.
5. **Automated Deployments:**  
   On code changes, the pipeline automatically builds, tests, and deploys new versions of your services to the EKS cluster, ensuring fast and reliable production updates.

---

## Modules & Components

### VPC
- Isolated networking for all resources.
- Public/private subnets across multiple AZs.
- Optional NAT Gateway, Internet Gateway.

### EKS (Elastic Kubernetes Service)
- Hosts containerized microservices in production.
- Managed node group, IAM roles, private networking.

### RDS (Relational Database Service)
- Managed PostgreSQL database.
- Secure password in AWS Secrets Manager, security group, subnet group.

### CI/CD Pipeline
- Automates build, scan, push, and deployment of microservices.
- Uses CodePipeline, CodeBuild, CodeDeploy, S3, and ECR.

### EC2 (Dev Only)
- Simple host for running containers and testing CodeDeploy.
- Installs Docker, Docker Compose, and CodeDeploy agent.

---

## Service Configuration

Services are defined in the `services` variable (see `terraform.tfvars`).  
Each service includes:
- `image`: Docker image name.
- `port` / `target_port`: Exposed and container ports.
- `environment`: Map of environment variables.

Modify services by editing the `services` map in your configuration.

---

## Local Development

For local development, use the provided `docker-compose.yaml` to spin up all services, including Postgres and RabbitMQ.
