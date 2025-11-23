#!/bin/bash
set -e

# Basic bootstrap for Amazon Linux 2: install Java, Maven, Git and Tomcat, build and deploy WAR
yum update -y

# Install Java 1.8, Maven and git

# If docker deployment is requested, install Docker and run the specified image
if [ "${use_docker_deploy}" = "true" ] && [ -n "${docker_image_repo}" ]; then
  # install docker
  yum install -y docker
  systemctl enable docker
  systemctl start docker

  # Attempt to pull and run the container
  docker pull ${docker_image_repo}:${docker_image_tag} || true
  docker rm -f app || true
  docker run -d --name app -p 8080:8080 --restart unless-stopped ${docker_image_repo}:${docker_image_tag} || true

  echo "Docker-based deployment finished (image: ${docker_image_repo}:${docker_image_tag})"
  exit 0
fi

# Fallback: build from source and deploy to Tomcat
yum install -y java-1.8.0-openjdk-devel maven git

APP_DIR=/home/ec2-user/app
mkdir -p ${APP_DIR}
chown ec2-user:ec2-user ${APP_DIR}

su - ec2-user -s /bin/bash -c "
  cd ~
  if [ -z \"${repo_url}\" ]; then
    echo 'No repo_url provided; skipping clone/build.'
    exit 0
  fi
  if [ -d app ]; then
    cd app && git fetch --all && git checkout ${repo_branch} || true
  else
    git clone ${repo_url} app || (cd app && git fetch --all && git checkout ${repo_branch})
    cd app || exit 0
  fi
  git checkout ${repo_branch} || true
  mvn clean package -DskipTests || true

  # Deploy webapp WAR to Tomcat (we will install Tomcat below)
"

# Install Tomcat as root
mkdir -p /opt/tomcat
cd /tmp
curl -sSL https://archive.apache.org/dist/tomcat/tomcat-$(echo ${tomcat_version} | cut -d. -f1)/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz -o tomcat.tar.gz
tar xzf tomcat.tar.gz -C /opt/tomcat --strip-components=1
chown -R ec2-user:ec2-user /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# Create systemd service for Tomcat
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=ec2-user
Group=ec2-user
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat || true

# Wait a bit for tomcat to create webapps dir
sleep 3

# If build produced webapp/target/*.war copy to tomcat webapps as ROOT.war
if [ -d /home/ec2-user/app/webapp/target ]; then
  war_file=$(ls /home/ec2-user/app/webapp/target/*.war 2>/dev/null | head -n1 || true)
  if [ -n "$war_file" ]; then
    cp -f "$war_file" /opt/tomcat/webapps/ROOT.war
    chown ec2-user:ec2-user /opt/tomcat/webapps/ROOT.war
    systemctl restart tomcat || true
  fi
fi

echo "Bootstrap complete"
