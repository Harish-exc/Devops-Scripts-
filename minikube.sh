# installing minikube on a Linux system with Docker as the driver
# System update & base packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Install Docker (official & correct)
curl -fsSL https://get.docker.com | sudo sh

# Add your user to Docker group (CRITICAL)
sudo usermod -aG docker $USER
newgrp docker

# Verify (must work without sudo)
docker ps

# Install Minikube (binary)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube


# Verify (NO sudo):

minikube version

# Install kubectl (verified)
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


# Verify:

kubectl version --client

# Start Minikube (THIS is the key)
minikube start --driver=docker


#  No sudo
# No force
# No permission issues

# Verify Kubernetes
kubectl get nodes
kubectl get pods -A
