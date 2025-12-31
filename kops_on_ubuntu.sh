#!/bin/bash
set -e

echo "===== kOps Kubernetes Cluster Setup ====="

# -----------------------------
# Variables (EDIT ONLY IF NEEDED)
# -----------------------------
CLUSTER_NAME="gorle.k8s.local"
AWS_REGION="us-east-1"
ZONES="us-east-1a,us-east-1b"
BUCKET_NAME="gorle-kops-state-$(date +%s)"
SSH_KEY="$HOME/.ssh/id_ed25519.pub"

# -----------------------------
# 1. Ensure PATH
# -----------------------------
export PATH=$PATH:/usr/local/bin

# -----------------------------
# 2. Install required packages
# -----------------------------
sudo apt update -y
sudo apt install -y unzip curl wget

# -----------------------------
# 3. Install AWS CLI v2
# -----------------------------
if ! command -v aws >/dev/null; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
fi

aws --version

# -----------------------------
# 4. Install kubectl
# -----------------------------
if ! command -v kubectl >/dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
fi

kubectl version --client

# -----------------------------
# 5. Install kops
# -----------------------------
if ! command -v kops >/dev/null; then
  wget -q https://github.com/kubernetes/kops/releases/download/v1.32.0/kops-linux-amd64
  chmod +x kops-linux-amd64
  sudo mv kops-linux-amd64 /usr/local/bin/kops
fi

kops version

# -----------------------------
# 6. Generate SSH key (if missing)
# -----------------------------
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
fi

# -----------------------------
# 7. Create S3 bucket (us-east-1 rule)
# -----------------------------
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

export KOPS_STATE_STORE="s3://$BUCKET_NAME"

echo "KOPS_STATE_STORE=$KOPS_STATE_STORE"

# -----------------------------
# 8. Create Kubernetes cluster
# -----------------------------
kops create cluster \
  --name "$CLUSTER_NAME" \
  --zones "$ZONES" \
  --control-plane-count 1 \
  --control-plane-size t3.small \
  --node-count 2 \
  --node-size t3.small \
  --node-volume-size 20 \
  --control-plane-volume-size 20 \
  --ssh-public-key "$SSH_KEY" \
  --networking calico \
  --topology public

# -----------------------------
# 9. Apply cluster
# -----------------------------
kops update cluster --name "$CLUSTER_NAME" --yes --admin

# -----------------------------
# 10. Validate cluster
# -----------------------------
kops validate cluster --name "$CLUSTER_NAME" --wait 10m

# -----------------------------
# 11. Verify nodes
# -----------------------------
kubectl get nodes -o wide

echo "✅ Kubernetes cluster created successfully"
