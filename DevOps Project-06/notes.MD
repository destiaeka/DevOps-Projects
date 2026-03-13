## Install Jenkins, Docker and Trivy. Create a  Container using Docker. || AWS LINUX
1. Install Java
```
sudo amazon-linux-extras enable corretto17
sudo yum install java-17-amazon-corretto -y
java --version
```

2. Add jenkins repo & install
```
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install jenkins -y
```

3. Setup Jenkins
```
[root@ip-172-31-32-5 ~]# cat /var/lib/jenkins/secrets/initialAdminPassword
4f92d6fd62c249b8a1f0530aa2e9d613
```

4. Install Docker
```
sudo amazon-linux-extras enable docker
sudo yum install -y docker

sudo usermod -aG docker $USER
newgrp docker
sudo chmod 777 /var/run/docker.sock

[root@ip-172-31-32-5 ~]# systemctl start docker
[root@ip-172-31-32-5 ~]# docker run -d --name sonar -p 9000:9000 :lts-community
```

5. Trivy
```
sudo yum update -y
sudo yum install -y curl tar gzip
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
```


## Create a TMDB API Key 
Seatch TMDB > Sign in Account > Setting > API > Create API > copy API Key

##  Install Prometheus and Grafana On the new Server.
1. Prometheus
```
[root@ip-172-31-32-5 ~]# sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false prometheus
[root@ip-172-31-32-5 ~]# wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
[root@ip-172-31-32-5 ~]# tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
[root@ip-172-31-32-5 ~]# sudo mkdir -p /data /etc/prometheus
[root@ip-172-31-32-5 ~]# cd prometheus-2.47.1.linux-amd64/
[root@ip-172-31-32-5 prometheus-2.47.1.linux-amd64]# sudo mv prometheus promtool /usr/local/bin/
[root@ip-172-31-32-5 prometheus-2.47.1.linux-amd64]# sudo mv consoles/ console_libraries/ /etc/prometheus/
[root@ip-172-31-32-5 prometheus-2.47.1.linux-amd64]# sudo mv prometheus.yml /etc/prometheus/prometheus.yml
[root@ip-172-31-32-5 prometheus-2.47.1.linux-amd64]# sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
[root@ip-172-31-32-5 prometheus-2.47.1.linux-amd64]# cd ..
rm -rf prometheus-2.47.1.linux-amd64.tar.gz
[root@ip-172-31-32-5 ~]# nano /etc/systemd/system/prometheus.service
[root@ip-172-31-32-5 ~]# cat /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
[root@ip-172-31-32-5 ~]# sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
● prometheus.service - Prometheus
     Loaded: loaded (/etc/systemd/system/prometheus.service; enabled; preset: disabled)
     Active: active (running) since Tue 2026-02-24 12:16:43 UTC; 4s ago
```

2. Node Exporter
```
[root@ip-172-31-32-5 ~]# sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false node_exporter
[root@ip-172-31-32-5 ~]# wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
[root@ip-172-31-32-5 ~]# tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
[root@ip-172-31-32-5 ~]# sudo mv \
  node_exporter-1.6.1.linux-amd64/node_exporter \
  /usr/local/bin/
[root@ip-172-31-32-5 ~]# rm -rf node_exporter*
[root@ip-172-31-32-5 ~]# nano /etc/systemd/system/node_exporter.service
[root@ip-172-31-32-5 ~]# cat /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
    --collector.logind

[Install]
WantedBy=multi-user.target
[root@ip-172-31-32-5 ~]# sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
Created symlink /etc/systemd/system/multi-user.target.wants/node_exporter.service → /etc/systemd/system/node_exporter.service.
● node_exporter.service - Node Exporter
     Loaded: loaded (/etc/systemd/system/node_exporter.service; enabled; preset: disabled)
     Active: active (running) since Tue 2026-02-24 12:19:42 UTC; 65ms ago

[root@ip-172-31-32-5 ~]# nano /etc/prometheus/prometheus.yml
[root@ip-172-31-32-5 ~]# cat /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets:
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
[root@ip-172-31-32-5 ~]# promtool check config /etc/prometheus/prometheus.yml
Checking /etc/prometheus/prometheus.yml
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax

[root@ip-172-31-32-5 ~]# curl -X POST http://localhost:9090/-/reload
```

!!AKSES IP-PUBLIC:9090/targets!!

3. Grafana
```
[root@ip-172-31-32-5 ~]# sudo yum update -y
sudo yum install -y wget tar libatomic git
[root@ip-172-31-32-5 ~]# sudo tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
[root@ip-172-31-32-5 ~]# sudo yum install grafana -y
[root@ip-172-31-32-5 ~]# sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server
Created symlink /etc/systemd/system/multi-user.target.wants/grafana-server.service → /usr/lib/systemd/system/grafana-server.service.
● grafana-server.service - Grafana instance
     Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; enabled; preset: disabled)
     Active: active (running) since Tue 2026-02-24 12:24:36 UTC; 647ms ago
```
4. Akses
- IP PUBLIC:3000 > admin:admin > Connections > Add data source > Prometheus > IP Public:9090 > Save & targets
- Dahsboard > Import > 1860 > load > import


## Install the Prometheus Plugin and Integrate it with the Prometheus server. 
1. Add Prometheus Plugin on Jenkins
Manage > Plugins > Install Prometheus

2. Configure prometheus.yml
```
[root@ip-172-31-32-5 ~]# nano /etc/prometheus/prometheus.yml
[root@ip-172-31-32-5 ~]# cat /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets:
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['100.24.30.51:8080']
[root@ip-172-31-32-5 ~]# curl -X POST http://localhost:9090/-/reload
[root@ip-172-31-32-5 ~]# systemctl restart jenkins
```

!!NOTED!!
AKSES IP PUBLIC:9090/targets --> pastikan jenkins up

3. Add Jenkins Monitoring Dahsboard
- Dahsboard > Import > 9964 > Load > import

## Email Integration With Jenkins and Plugin setup. 
1. Create App passwod
https://myaccount.google.com/apppasswords

2. Create Jenkins Credentials
Manage > Credentials > usn: email > pass: token

3. Configure Jenkins
- Manage Jenkins > System > Extended E-mail Notification > SMTP server : smtp.gmail.com > SMTP Port : 587 > Advance > Credential select that you create > Use TLS
- E-mail Notification > SMTP Server : smtp.gmail.com > Advance > Use SMTP Authentication > user : usn email > password : password app from gmail > Use TLS > SMTP Port : 587 > Test configuration > Save

## Install Plugins like JDK,  Scanner, Nodejs, and OWASP Dependency Check
1. Manage > Plugin > Install
    - Eclipse Temurin Installer 
    - SonarQube Scanner 
    - NodeJs 

2. Tools > JDK Installation > name : jdk17 (disesuaikan jenkinsfile) > Sonar Scanner > name : sonar-scanner > NodeJS > name: node16
3. System 
3. Job > + > name: netflix > pipeline


##  Create a Pipeline Project in Jenkins using a Declarative Pipeline 
1. My Account > Security > Generate Token > name > type:Global Analys Token > Generate
2. Administration > Webooks > Create > Name : webhook > URL : http://100.24.30.51:8080/sonarqube-webhook/ > create
3. Credentials > Secret Text > Secret : token from sonarqube > id: sonar-token (sesuaikan jenkinsfile) > Save
4. System > Add Sonar Installation > name: sonar-server (sesuaikan jenkinsfile) > IP sonarqube > Authentication pilih credentials yang dibuat

##  Test Pipeline 
Job > Netflix > script
```
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SONAR_AUTH_TOKEN = credentials('sonar-token')
        TMDB_V3_API_KEY = '0dce023f62e205b6041ad5056a414ea5'
    }
    stages {
        stage('Clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/destiaeka/Netflix-clone.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix '''
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'destiaeka38@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}
```

Save > Build Now

##  Install OWASP Dependency Check Plugins 
1. manage > plugins >  OWASP Dependency-check
2. tools > Dependency-Check installations > Name: DP-Check > Installation automatic from github
3. tambahkan stage trivy sebelum post
```
stage('TRIVY FS SCAN') {
    steps {
        dir('DevOps Project-06') {
            sh "trivy fs . > ../trivyfs.txt"
        }
    }
}
```


##  Docker Image Build and Push 
1. manage > plugins > install dockef & docker pipeline
2. docker hub > account > access token > Generate
3. credential > username & password > usn: usn dockerhub > password: token
4. tools > docker > Name: docker > install automatic
5. system > Declarative Pipeline (Docker) > docker label : docker > registry url kosong gpp > credentials : pilih yang dibuat
```
script:
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SONAR_AUTH_TOKEN = credentials('sonar-token')
        TMDB_V3_API_KEY = '0dce023f62e205b6041ad5056a414ea5'
    }
    stages {
        stage('Clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/destiaeka/Netflix-clone.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix '''
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                        sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_V3_API_KEY} -t netflix ."
                        sh "docker tag netflix destiaeka/netflix:latest"
                        sh "docker push destiaeka/netflix:latest"
                    }
                }
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage('Deploy to container'){
            steps{
                sh 'docker run -d --name netflix -p 8081:80 destiaeka/netflix:latest'
            }
        }
    }
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'destiaeka38@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}
```

##  INSTALL K8S JENKINS 
```
[root@ip-172-31-32-5 ~]# sudo yum update -y
sudo yum install -y curl
[root@ip-172-31-32-5 ~]# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
[root@ip-172-31-32-5 ~]# chmod +x kubectl
sudo mv kubectl /usr/local/bin/
[root@ip-172-31-32-5 ~]# kubectl version --client
Client Version: v1.35.1
Kustomize Version: v5.7.1
```

## INSTALL K8S MASTER - AGENT 
```
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version --client
kubeadm version
```

##  ENABLE IP FORWARD & CONTAINERD 
```
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl status containerd
```

##  MASTER AGENT 
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
source ~/.bashrc
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

##  JOIN MASTER -NODE WORKER 
```
sudo kubeadm join 172.31.39.255:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx
```
##  MASTER NODE 
```
cat ~/.kube/config --> copy isinya simpan di file secret-file.txt
```
## CREDENTIALS & PLUGIN JENKINS 
manage > credential > (+) > secert file > updload file secret-file.txt > save
plugin > install kubernetes & kubernetes CLI

## INSTALL NODE EXPORTER MASTER & AGENT 
```
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv \
  node_exporter-1.6.1.linux-amd64/node_exporter \
  /usr/local/bin/
rm -rf node_exporter*
nano /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
    --collector.logind

[Install]
WantedBy=multi-user.target
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

##  SERVER JENKINS 
```
nano /etc/prometheus/prometheus.yml
  - job_name: node_export_masterk8s
    static_configs:
      - targets: ["<master-ip>:9100"]

  - job_name: node_export_workerk8s
    static_configs:
      - targets: ["<worker-ip>:9100"]
promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload
http://<ip>:9090/targets
```

##  SCRIPT JENKINS 
```
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SONAR_AUTH_TOKEN = credentials('sonar-token')
        TMDB_V3_API_KEY = '0dce023f62e205b6041ad5056a414ea5'
    }
    stages {
        stage('Clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/destiaeka/Netflix-clone.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix '''
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                        sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_V3_API_KEY} -t netflix ."
                        sh "docker tag netflix destiaeka/netflix:latest"
                        sh "docker push destiaeka/netflix:latest"
                    }
                }
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage('Deploy to container'){
            steps{
                sh 'docker run -d --name netflix -p 8081:80 destiaeka/netflix:latest'
            }
        }
        stage('Deploy to kubernets'){
            steps{
                script{
                    dir('Kubernetes') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }
    }
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'destiaeka38@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}
```
