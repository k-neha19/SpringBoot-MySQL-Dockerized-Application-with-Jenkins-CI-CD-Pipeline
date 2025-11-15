# Spring Boot + MySQL app ready for Docker Compose (dev) or Kubernetes (prod).


- This project demonstrates deploying a Spring Boot application with a MySQL database on Kubernetes, using Jenkins pipelines for automation. The setup ensures that the application pod starts only after MySQL is healthy, and all resources can be deployed or removed with parameterized pipeline stages.

## Overview

This project demonstrates how to Dockerize a Spring Boot application connected to a MySQL database, and how to automate its build and deployment using a Jenkins pipeline. The project includes:

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/c937ef7f-c5d1-4e2f-b7db-396beff30d0a" />

- **Spring Boot application** packaged as a Docker container
- **MySQL database** running in a separate Docker container
- A shared Docker network for container communication
- A **Jenkins pipeline** that builds, deploys, and manages both containers intelligently

---

## Repository Contents

- `Dockerfile` — Builds Docker image for the Spring Boot app  
- `application.properties` — Configured for MySQL connection via Docker container hostname  
- `Jenkinsfile` — Pipeline script for CI/CD automation  
- Spring Boot source code and Maven project files

---

## System Requirements
- ubuntu 24.04 LTS
- 2 CPU + 4 GB RAM
- Install - **java-17, jenkins, docker**
- Jenkins Tools: **maven**
- Jenkins Plugins: **stage view**

## Prerequisites
- Jenkins installed with Docker and Maven available on the agent node  
- Docker installed and running on the Jenkins agent machine  
- Git access to this repository



---
## How It Works

1. **Docker Network Setup**  
   Jenkins pipeline creates a Docker network `app-network` if it does not already exist.

2. **MySQL Container**  
   The pipeline checks if a MySQL container named `mysql-container` is running; if not, it starts or creates it with root password `1234`.

3. **Build Spring Boot Application**  
   Runs Maven to clean and package the Spring Boot JAR without tests.

4. **Build Spring Boot Docker Image**  
   Uses the provided `Dockerfile` to build a Docker image tagged as `spring-app`.

5. **Run Spring Boot Container**  
   Checks if a container named `spring-app-container` is running. If not, it removes any stopped containers with the same name and runs a new container attached to the Docker network.

6. **Connectivity**  
   The Spring Boot app connects to MySQL via hostname `mysql-container` on port 3306.

---

## admin login

- username: admin
- password: admin
---

