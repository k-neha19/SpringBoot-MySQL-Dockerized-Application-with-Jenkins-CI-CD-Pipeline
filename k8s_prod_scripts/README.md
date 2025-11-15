# Spring Boot + MySQL Kubernetes CI/CD Deployment

## Project Overview
This project demonstrates a **full CI/CD pipeline using Jenkins** for deploying a **Spring Boot application** backed by **MySQL** on a **Kubernetes cluster**. The deployment uses **kubeadm cluster** on AWS EC2, with automated kubeconfig setup for Jenkins.

The Spring Boot application is containerized via **Docker** and deployed on Kubernetes using **Deployment** and **Service** manifests. The CI/CD pipeline handles deployment, readiness checks, and removal of resources.

### Access the application 
- **http://CONTROL_PLANE_PUBLIC_IP:30088**
---

## Features

- Deploy a **Spring Boot application** from DockerHub.
- Deploy a **MySQL 8.0 database** with secure password management via Kubernetes Secrets.
- Fully automated **Jenkins pipeline** for deployment and removal.
- Namespace isolation for application stack (`sak-shetty` namespace).
- NodePort service to expose the application externally.
- Init container to **wait for MySQL readiness** before Spring Boot startup.
- Supports **deploy** and **remove** actions via Jenkins pipeline parameters.
- Automatic **kubeconfig setup** for Jenkins access.

---

## Tools and Configurations

### Tools Used
- **Jenkins**: CI/CD server  
- **GitHub**: Version control  
- **Docker**: Containerization of Spring Boot application  
- **Kubernetes**: Deployment and service orchestration  
- **kubectl**: Kubernetes CLI  

### Manual Server Configuration
1. **Install kubectl on Jenkins server** (if not installed):

   ```bash
   sudo apt update -y
   sudo snap install kubectl --classic
   ```

2. **Copy kubeconfig from control plane to Jenkins server**:

   ```bash
   bash fetch-and-prepare-kubeconfig.sh
   ```

   This script will:

   * Prompt for control plane IP and PEM key.
   * Copy `kubeconfig.yaml` to `/home/jenkins/kubeconfig_for_jenkins/`.
   * Set proper permissions.
   * Test connectivity to Kubernetes cluster.

3. Ensure the Jenkins server can access the Kubernetes control plane on port `6443`.

---

## Project Structure

```
k8s_prod_scripts/
├── Jenkinsfile                  # Jenkins pipeline
├── namespace.yml                # Kubernetes namespace definition
├── db_deploy_svc.yml            # MySQL Deployment + Service + Secret
├── app_deploy_svc.yml           # Spring Boot Deployment + Service
```

---

## Working Procedure

1. **Prepare Kubernetes cluster**:

   * Ensure kubeadm control plane is running.
   * Ensure Jenkins server can connect using the PEM key.
   * Run the kubeconfig setup script.

2. **Build Docker image for Spring Boot** (done already in this project):

   ```bash
   docker build -t sakit333/webapp_dev:latest .
   ```

3. **Push image to DockerHub**:

   ```bash
   docker push sakit333/webapp_dev:latest
   ```

4. **Deploy via Jenkins pipeline**:

   * Go to Jenkins → New Item → Pipeline.
   * Select **Pipeline from SCM** → GitHub repository.
   * Set `Jenkinsfile` path: `k8s_prod_scripts/Jenkinsfile`.
   * Run the pipeline.
   * Choose `deploy` action.

5. **Access Application**:

   * Check services:

     ```bash
     kubectl get all -n sak-shetty
     ```
   * Access Spring Boot app externally using NodePort:

     ```
     http://<control-plane-public-ip>:30088
     ```

---

## Jenkins Pipeline Details

### Parameters

* `ACTION`: `deploy` or `remove`

### Environment Variables

* `K8S_NAMESPACE`: Kubernetes namespace for the app (`sak-shetty`)
* `APP_NAME`: Spring Boot application name
* `DB_NAME`: MySQL database pod name
* `APP_IMAGE`: Docker image for Spring Boot
* `DB_IMAGE`: MySQL image
* `APP_PORT`: Container port for Spring Boot
* `NODE_PORT`: NodePort for external access
* `DB_PASSWORD`: MySQL root password
* `DB_NAME_MYSQL`: MySQL database name
* `KUBE_PROJECT_DIR`: Path to k8s manifests
* `KUBECONFIG`: Path to kubeconfig on Jenkins server

### Pipeline Stages

1. **Verify Kubernetes Access**

   * Checks cluster connectivity and nodes.
2. **Create Namespace**

   * Creates namespace if not present.
3. **Deploy MySQL**

   * Deploys MySQL with Secret for password and ClusterIP service.
4. **Wait for MySQL Ready**

   * Waits until MySQL pod is fully ready.
5. **Deploy Spring Boot App**

   * Deploys Spring Boot app with init container to wait for MySQL.
6. **Show Resources After Deployment**

   * Lists all pods, deployments, and services.
7. **Remove Spring Boot App**

   * Deletes Spring Boot deployment and service.
8. **Remove MySQL**

   * Deletes MySQL deployment, service, and secret.
9. **Remove Namespace**

   * Deletes namespace.
10. **Show Resources After Removal**

    * Verifies namespace deletion.

---

## Notes

* MySQL root password and database are stored in **base64-encoded Kubernetes Secrets**.
* Application reads database credentials via environment variables injected from Secrets.
* Ensure **NodePort** (`30088`) is allowed in AWS Security Groups for external access.
* Do not modify the `Dockerfile` or `application.properties` if they are already working.

---

## Author

* Developed and maintained by **@sak_shetty**

---
