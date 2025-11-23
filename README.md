# Java CI/CD: Jenkins → Docker → ECR → EKS

This repository contains a sample Java web application and infrastructure/pipeline artifacts used to demonstrate a CI/CD flow: Jenkins builds the app with Maven, produces a Docker image, pushes it to Amazon ECR, and the image is deployed to Amazon EKS.

What I changed/added
- `Jenkinsfile` — declarative pipeline that builds, tags (BUILD_NUMBER + latest), pushes to ECR and updates the Kubernetes manifest in `Kubernetes-Manifests-file`.
- `Kubernetes-Manifests-file/deploy_svc.yml` — updated to reference this AWS account's ECR repo and to use `java-webapp` naming (matches deployed resources).

Quick links
- Kubernetes manifest: `Kubernetes-Manifests-file/deploy_svc.yml`
- Jenkins pipeline: `Jenkinsfile`

How to use (summary)
1. Ensure Jenkins has a job using the `Jenkinsfile` from this repo (Pipeline: Pipeline script from SCM or multibranch pipeline).
2. In Jenkins, add a secret-text credential with id `my-git-pattoken` that has push access to this repo so the pipeline can commit manifest updates.
3. Make sure the EC2/Jenkins instance has the correct IAM permissions (or add AWS credentials in Jenkins) to push to ECR.
4. The Jenkinsfile tags images as `${BUILD_NUMBER}` and also as `latest`. The manifest in the repo will be updated to reference the build tag.

Advanced / production-ready notes
-------------------------------
- Dockerfile and runtime: this repository supports a Chainguard minimal Java runtime via the `RUNTIME_IMAGE` build-arg. The Dockerfile is multi-stage and will work with `images.chainguard.dev/java:17` by default. To build locally using Chainguard:

```bash
docker build --build-arg RUNTIME_IMAGE=images.chainguard.dev/java:17 -t java-webapp:latest .
```

- Jenkinsfile environment: For safety the `Jenkinsfile` no longer hardcodes the AWS account id. Configure one of these in Jenkins:
  - set `REPOSITORY_URI` as a job/global environment variable (preferred), or
  - set `AWS_ACCOUNT_ID` and `AWS_DEFAULT_REGION` so the pipeline can derive the repo URI.

- Add Maven Wrapper: generate locally with `mvn -N io.takari:maven:wrapper` and commit `mvnw`, `mvnw.cmd` and `.mvn/wrapper` to the repo for reproducible builds.

- Secrets & credentials: never commit secrets. Use Jenkins Credentials for:
  - Git token (credential id `my-git-pattoken` used in the Jenkinsfile), and
  - AWS credentials or rely on the EC2 instance profile to authenticate to ECR.

## Validation — screenshots

Add screenshots to `docs/screenshots/` to show proof of a successful run. Recommended filenames (place your PNGs there):

- `jenkins_console.png` — Jenkins job console output (build, docker push, git commit)
- `ecr_tags.png` — ECR repository view showing tags (BUILD_NUMBER + latest)
- `kubectl_svc.png` — output of `kubectl get svc` showing the LoadBalancer hostname
- `app_page.png` — the webapp page served from the LoadBalancer

Embed examples (will render on GitHub once the files exist):

![Jenkins console](docs/screenshots/jenkins_console.png)
![ECR tags](docs/screenshots/ecr_tags.png)
![kubectl svc](docs/screenshots/kubectl_svc.png)
![App page](docs/screenshots/app_page.png)

To add and commit these screenshots from your workstation:

```bash
git checkout -b feature/practice
mkdir -p docs/screenshots
# copy your PNGs into docs/screenshots/
git add docs/screenshots/*.png README.md
git commit -m "docs: add validation screenshots"
git push origin feature/practice
```

After pushing, open a Pull Request from `feature/practice` → `main` to publish the images on GitHub.


Accessing the running app
- After deployment, check the service external hostname (type LoadBalancer) in the cluster. Example from my run:

```
http://a29b4958d91b647e79d14f28ae8ee1f9-2127306800.us-east-2.elb.amazonaws.com/
```

Recommended README screenshots
- Jenkins job run console output (show build, docker push, and git commit step)
- ECR repository showing the pushed image/tag
- kubectl get svc output showing the LoadBalancer hostname
- Application page served from the LoadBalancer (tomcat/webapp page)

How to push these repo changes to GitHub
1. From your workstation, run:

```bash
git checkout -b feature/practice
git add Jenkinsfile Kubernetes-Manifests-file/deploy_svc.yml README.md
git commit -m "Add Jenkinsfile, update manifest and README for CI/CD"
git push origin feature/practice
```

2. Create a Pull Request on GitHub from `feature/practice` → `main` and merge it. Alternatively:

```bash
# merge locally (if you have permissions)
git checkout main
git pull origin main
git merge --no-ff feature/practice
git push origin main
```

Cleaning up AWS resources (to avoid charges)
- EKS cluster (deletes worker nodes, load balancers, etc.):
  ```bash
  eksctl delete cluster --name devops-cluster --region us-east-2
  ```
- Destroy Terraform-managed EC2 (if you used the terraform in `terraform/`):
  ```bash
  cd terraform
  terraform destroy -var-file=environments/dev.tfvars
  ```
- Remove ECR repository (optional):
  ```bash
  aws ecr delete-repository --repository-name demo --region us-east-2 --force
  ```

Notes & security
- Do not commit credentials or PEM keys to the repository. Use Jenkins credentials store or IAM instance profiles.
- Consider adding a Maven Wrapper (`mvnw`) to the project for reproducible builds.
- For automation and safer deployment, consider adding ArgoCD to perform GitOps (it will keep the cluster in sync with the repo manifest).

If you want I can:
- push these local edits to `feature/practice` (I will prepare the git commands and you can run them), or
- attempt to push from the jumphost (requires a git token/credential configured on that host).

Questions? Tell me whether you want me to prepare the PR or to run the destroy commands for you now (I can run `eksctl delete cluster` and `terraform destroy` if you confirm you want to tear down everything). 
# 🚀 Jenkins CI/CD + Docker for Java Web App 


This is a sample project demonstrating CI/CD pipeline using Maven, Jenkins, Docker, and EKS.

## Project Architecture

![Architecture Diagram](https://github.com/arumullayaswanth/maven-jenkins-cicd-docker-eks-project/blob/e2fcc40d9a5d1fb3f25dd96807b736d274f04c50/Images/image.png?raw=true)

### Objective:

1. Deploy your Java (Maven) web app from GitHub to an EC2 server using Jenkins and Docker. You’ll push code → Jenkins builds WAR → Docker builds image → Runs app.

This guide walks you through **deploying a Java Web App** using:
- ✅ Maven (to build)
- ✅ Docker (to containerize and run)
- ✅ Jenkins (to automate everything)
- ✅ EC2 (to host Jenkins)

---

## 🧱 PART 1: Setup Jenkins EC2 Server

### 🔧 STEP 1: Launch EC2 in AWS
1.	Go to AWS Console → EC2 → Launch Instance
2.	Instance Name: jenkins-server
3.	OS: Choose Ubuntu 20.04
4.	Instance Type: t2.medium (2GB RAM minimum for Docker + Jenkins)
5.	Key Pair: Create/download a new key pair (save .pem file)
6.	Network Settings:
  o	Open the ports below:
	-  ✅ SSH (22)
   -	✅ HTTP (80)
	-  ✅ Custom TCP → Port 8080 (for Jenkins)
7.	Click Launch Instance

➡️ Done? Copy the **Public IPv4** address, you’ll need it.


---

### 🖥️ STEP 2: Connect to EC2

```bash
ssh -i your-key.pem ubuntu@<your-ec2-ip>
```

---

### ⚙️ STEP 3: Install Java, Maven, Git, Docker

```bash
sudo apt update -y
sudo apt install maven git -y
sudo apt install -y openjdk-17-jdk
java -version
mvn -v
git --version
```

✅ Install Docker:

```bash
# Update and install prerequisites
sudo apt update
sudo apt install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

# Add Docker's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Enable and test Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo docker run hello-world
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl status docker

```

🔄 If Docker Is Not Running
1. If it shows inactive or failed, you can try restarting and checking logs:
   ```bash
   sudo systemctl restart docker
   sudo journalctl -u docker --no-pager --lines=30

   ```



---

### 🤖 STEP 4: Install Jenkins

```bash

sudo apt update
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
```
```bash
sudo systemctl status jenkins
```
✅ Give Jenkins Docker access:

```bash
sudo usermod -aG docker jenkins
id jenkins


#Restart the instance (or logout and login again):
sudo reboot
```

✅ Open Jenkins in browser:
```
http://<your-ec2-ip>:8080
```

```bash
#Get the first-time password:

sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

- Paste password → Install Suggested Plugins → Create Admin

---

## 🚚 PART 2: Prepare GitHub Repo

### 🗂️ Your Project Structure (✅ you already shared)

Make sure your GitHub project contains:

- `Dockerfile` (your final one)
- `pom.xml` (for main + webapp module)
- `webapp/` folder (contains `index.jsp`, etc.)
- `.gitignore` (exclude `target/`)

### 🆙 Push Code to GitHub (if not already)

```bash
git init
git remote add origin https://github.com/<your-username>/<your-repo>.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

---

## 🛠️ PART 3: Create Jenkins CI/CD Pipeline

### 🔐 STEP 6: Add GitHub Credentials to Jenkins

1. Go to Jenkins → Manage Jenkins → Credentials → (Global) → Add Credentials
2. Choose:
   - Kind: **Username & Password** OR **GitHub PAT**
   - ID: `github-creds`

---

### ⚙️ STEP 7: Create a Jenkins Pipeline Job

1. Go to Jenkins Dashboard → **New Item**
2. Name: `java-webapp-cicd`
3. Choose: **Pipeline** → Click **OK**

In the "Pipeline" section → choose **“Pipeline Script”** and paste this:

```groovy

pipeline {
  agent any
  environment {
    IMAGE_NAME = 'java-webapp'
  }
  stages {
    stage('Clone') {
      steps {
        git credentialsId: 'github-creds', url: 'https://github.com/arumullayaswanth/maven-jenkins-cicd-docker-eks-project.git'
      }
    }
    stage('Maven Build') {
      steps {
        sh 'mvn clean install -pl webapp -am'
      }
    }
    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME .'
      }
    }
    stage('Run Container') {
      steps {
        sh '''
        docker rm -f java-webapp-container || true
        docker run -d -p 80:8080 --name java-webapp-container $IMAGE_NAME
        '''
      }
    }
  }
}


```

---


---

## 🚀 PART 4: Run Your Jenkins Job

### ▶️ STEP 8: Start the Pipeline

1. Click **Build Now**
2. Console Output shows:
   - Git Clone ✅
   - Maven Build WAR ✅
   - Docker Image ✅
   - Docker Container ✅

---

### 🌍 STEP 9: Open Web App

In browser:
```
http://<your-ec2-ip>
```
user:admin 
password: admin

🎉 You’ll see your `index.jsp` from the WAR file running inside Tomcat + Docker!

---

## 📦 PART 5: Bonus Commands

```bash
# List containers
docker ps

# # All containers (including stopped)
docker ps -a 

# Stop container
docker stop java-webapp-container

# Remove container
docker rm java-webapp-container

# Remove image
docker rmi java-webapp

#🔁 Rebuild the Docker Image
docker build -t java-webapp .

#🚀 Run the Container (exposing port 8080)
docker run -d --name java-webapp-container -p 8080:8080 java-webapp

#📂 See Container Logs
docker logs java-webapp-container

# 📥 Copy Files From a Running Container
docker cp java-webapp-container:/opt/tomcat/webapps/webapp.war ./webapp.war

#🖥️ Access Container Shell
docker exec -it java-webapp-container bash

#💥 Force Remove All Stopped Containers and Dangling Images
docker container prune -f
docker image prune -f

#📋 List Docker Images

docker images

```

---

## 📊 Architecture Diagram (Text View)

```
[GitHub] 
   |
   | (Push code)
   v
[Jenkins EC2 Server]
   |--> Maven Build WAR
   |--> Docker Build Image
   |--> Docker Run Container
   |
   v
[Your Web App] → http://<EC2-IP>
```

---

### ✅ Diagram to Understand (Kid-style)

```
+---------------------+      GitHub Push       +---------------------+
|   Developer Laptop  |  ------------------->  |     GitHub Repo     |
+---------------------+                        +---------------------+
                                                    |
                                                    v
      +------------------------------------------------------------+
      | EC2 Ubuntu Server (Jenkins + Docker + Java + Maven)        |
      |                                                            |
      |  [ Jenkins Pipeline ]                                      |
      |   1. Clone Code from GitHub                                |
      |   2. Build WAR using Maven                                 |
      |   3. Build Docker image using Dockerfile                   |
      |   4. Run Container exposing port 80                        |
      +------------------------------------------------------------+
                                                    |
                                                    v
                                 Web App available at http://<EC2-IP>
```

---

## ✅ What You Achieved

| ✅ Task | Done |
|--------|------|
| EC2 created with right ports | ✅ |
| Jenkins installed and running | ✅ |
| Docker, Maven, Java setup | ✅ |
| Jenkins pipeline for your code | ✅ |
| WAR built and deployed inside Docker | ✅ |
| Web app live on EC2 | ✅ |

---
## 🚀 PART 4: Build Artifacts Location (Workspace)
## ✅ 1. Build Artifacts Location (Workspace)

Every time Jenkins runs a job, it stores all the files in the workspace.

### ✅ Option A: GUI – Jenkins Dashboard

1. Go to your Jenkins job.
2. Click on the last **successful build**.
3. Click on **"Workspace"** (left sidebar).
4. You'll see:
   - Your project folder
   - Compiled files
   - `target/` folder → Contains `.war` file:
     ```
     /var/lib/jenkins/workspace/java-webapp-cicd/target/webapp.war
     ```

### ✅ Option B: Jenkins Server (Linux Terminal)

```bash
cd /var/lib/jenkins/workspace/<your-job-name>/
ls -l

cd target/
ls -l
# webapp.war should be here
```

---

### ✅ 2. If You Used archiveArtifacts in Pipeline

If your Jenkinsfile has:

```groovy
archiveArtifacts artifacts: 'target/*.war', fingerprint: true
```

Then Jenkins archives the WAR file under:

> Jenkins → Job → Build → **"Archived Artifacts"**

---

### ✅ 3. If You Built Docker Image

1. If Jenkins builds a Docker image, the WAR gets copied into the Tomcat image in the Docker layer, but not stored locally on Jenkins after build (unless you keep a copy manually).

```bash
docker exec -it <container_id> bash
cd /opt/tomcat/webapps/
ls -l
# You’ll see: webapp.war and expanded webapp/
```


---

## ✅ Summary

| Case | Where to Look |
|------|------------------------------|
| Maven .war build | `/var/lib/jenkins/workspace/<job>/target/webapp.war` |
| GUI – Workspace | Jenkins → Job → Build → Workspace |
| Archived Artifacts | Jenkins → Job → Build → Archived Artifacts |
| Docker container WAR file | `/opt/tomcat/webapps/` inside container |

---

## 💣 Project Destroy Option (When You Don't Need It Anymore)



### ✅ Updated Jenkinsfile with Destroy Option

```groovy
pipeline {
  agent any
  environment {
    IMAGE_NAME = 'java-webapp'
    CONTAINER_NAME = 'java-webapp-container'
  }
	
  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Check this if you want to destroy everything (container, image, workspace)')
  }

  stages {
    stage('Clone') {
      when { expression { !params.DESTROY } }
      steps {
        git credentialsId: 'github-creds', url: 'https://github.com/arumullayaswanth/maven-jenkins-cicd-docker-eks-project.git'
      }
    }

    stage('Maven Build') {
      when { expression { !params.DESTROY } }
      steps {
        sh 'mvn clean install -pl webapp -am'
      }
    }

    stage('Build Docker Image') {
      when { expression { !params.DESTROY } }
      steps {
        sh 'docker build -t $IMAGE_NAME .'
      }
    }

    stage('Run Container') {
      when { expression { !params.DESTROY } }
      steps {
        sh '''
          docker rm -f $CONTAINER_NAME || true
          docker run -d -p 80:8080 --name $CONTAINER_NAME $IMAGE_NAME
        '''
      }
    }

    stage('Destroy Everything') {
      when { expression { params.DESTROY } }
      steps {
        echo "🧨 Destroying container, image, and cleaning workspace..."

        sh '''
          echo "Stopping and removing container..."
          docker rm -f $CONTAINER_NAME || true

          echo "Removing Docker image..."
          docker rmi -f $IMAGE_NAME || true

          echo "Cleaning Jenkins workspace..."
          rm -rf * || true
        '''
      }
    }
  }

  post {
    always {
      echo "✅ Pipeline completed."
    }
  }
}

```

---

### ✅ How to Use It

1. Click **“Build with Parameters”**
2. ✅ Tick the checkbox **“DESTROY”**
3. 💥 The pipeline will:
   - Stop and remove the container
   - Remove the image
   - Clean the workspace

---

### 🔥 Output Example (when DESTROY is checked)

```
🧨 Destroying container, image, and cleaning workspace...
Stopping and removing container...
Removing Docker image...
Cleaning Jenkins workspace...
```


-----
---

## 🧩 Build & Run with Chainguard runtime (recommended minimal runtime)

The included `Dockerfile` supports building a Tomcat image using a minimal Chainguard Java runtime.
By default the Dockerfile uses `images.chainguard.dev/java:17` as the runtime image. If you prefer a
different runtime tag, pass `--build-arg RUNTIME_IMAGE=...`.

Example build (PowerShell):

```powershell
cd 'e:\Java_project\maven-jenkins-cicd-docker-eks-project'
docker build --build-arg RUNTIME_IMAGE=images.chainguard.dev/java:17 -t java-webapp:chainguard .
docker run --rm -p 8080:8080 java-webapp:chainguard

# Open http://localhost:8080
```

If `images.chainguard.dev/java:17` isn't available in your environment or you'd like to test quickly,
you can override with another JVM-enabled image (for example a distroless Java image):

```powershell
docker build --build-arg RUNTIME_IMAGE=gcr.io/distroless/java:11 -t java-webapp:distroless .
```

Notes:
- Chainguard/distroless images are minimal and often lack a shell; the Dockerfile runs Tomcat via the
  Java bootstrap so the container can run without `/bin/sh`.
- If the runtime image you pick doesn't include `java` on PATH, the container will fail to start. You can
  always override `RUNTIME_IMAGE` with an image you control.

## 🔁 CI: Build, push image and deploy to EC2 (recommended container flow)

If you want Jenkins to build a Docker image and have the EC2 instance pull & run it (diagram flow), do the following:

1. Configure a container registry (ECR recommended for AWS) and create a repository (e.g. `myapp`).
2. Update Terraform variables before applying so the EC2 user-data knows which image to pull:

   ```hcl
   # terraform/terraform.tfvars
   use_docker_deploy = true
   docker_image_repo = "<your-account>.dkr.ecr.us-east-1.amazonaws.com/myapp"
   docker_image_tag  = "latest"
   ```

3. Sample Jenkins pipeline steps to build and push to ECR (replace with GHCR/DockerHub commands if you use those registries):

```groovy
pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    IMAGE_REPO = '123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
  }
  stages {
    stage('Checkout') {
      steps { git url: 'https://github.com/your/repo.git', branch: 'main' }
    }
    stage('Build') {
      steps { sh 'mvn -B -DskipTests clean package' }
    }
    stage('Build & Push Docker') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 123456789012.dkr.ecr.$AWS_REGION.amazonaws.com
          docker build --build-arg RUNTIME_IMAGE=images.chainguard.dev/java:17 -t ${IMAGE_REPO}:${IMAGE_TAG} .
          docker push ${IMAGE_REPO}:${IMAGE_TAG}
        '''
      }
    }
  }
}
```

4. After pushing the image, Terraform-provisioned EC2 (with `use_docker_deploy=true`) will pull and run the image on boot. For rolling updates you can SSH + docker pull/run or add a small script to restart the container.

Notes:
- Make sure the EC2 instance has network access to the registry. For private ECR, assign an instance profile (IAM role) with permissions: `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer` and `ec2:DescribeInstances` as needed, or have Jenkins push to a public registry.
- Alternatively, have Jenkins SSH into the EC2 instance and run `docker pull` + `docker run` remotely if you prefer not to grant EC2 ECR permissions.


