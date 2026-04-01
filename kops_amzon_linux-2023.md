✅ Install kOps on Amazon Linux 2023

Instance: m7i-flex.large (2 vCPU, 8 GB)
OS: Amazon Linux 2023
User: ec2-user

🧱 STEP 0: EC2 & IAM (DO THIS FIRST)
IAM Role attached to EC2 (MANDATORY)

Attach a role with permissions for:

EC2

S3

IAM

ELB

AutoScaling

Route53

This avoids using aws configure.

Verify:

aws sts get-caller-identity


If this fails → STOP and fix IAM.

🔄 STEP 1: Update system
sudo dnf update -y
sudo dnf install -y curl wget unzip git jq
☸️ STEP 2: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/


Verify:

kubectl version --client

🚀 STEP 3: Install kOps (OFFICIAL METHOD)
curl -Lo kops https://github.com/kubernetes/kops/releases/latest/download/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/


Verify:

kops version

☁️ STEP 4: Create S3 bucket for kOps state
export KOPS_STATE_STORE=s3://kops-state-$(date +%s)
aws s3 mb $KOPS_STATE_STORE


Confirm:

aws s3 ls

🌍 STEP 5: Choose Cluster Name

Use public DNS style (recommended):


export KOPS_CLUSTER_NAME=kops.cluster.local       -> if your dont want ROUTE53


export KOPS_CLUSTER_NAME=kops.demo.example.com    -> if you want route 53


If you don’t own a domain, Route53 private hosted zone will be created automatically.

step -6 
🚀 Use THIS kOps command (Recommended for your setup)   || if your using the free tier use this 

kops create cluster \
  --name=$KOPS_CLUSTER_NAME \
  --state=$KOPS_STATE_STORE \
  --zones=us-east-1a \
  --node-count=1 \
  --node-size=m7i-flex.large \
  --control-plane-size=m7i-flex.large \
  --control-plane-volume-size=30 \
  --node-volume-size=30 \
  --networking=calico \
  --yes


This will:

Create a stable control plane

Avoid OOM issues

Allow Metrics Server & HPA

Behave close to EKS
⏳ STEP 7: Wait for cluster to be ready

kops validate cluster --wait 10m


Expected:

Your cluster kops.demo.example.com is ready

📊 STEP 8: Install Metrics Server (kOps way)

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


Verify:

kubectl get pods -n kube-system | grep metrics
kubectl top nodes

🔍 STEP 9: Verify everything
kubectl get nodes
kubectl get pods -A

🧠 IMPORTANT FACTS (READ CAREFULLY)
✅ Why this setup is stable

8 GB RAM prevents OOM

AL2023 optimized for AWS

Proper kubelet TLS (no insecure flags)

Real EC2 networking

Metrics Server works correctly

❌ Do NOT

Run kOps with sudo

Use Ubuntu 2GB nodes

Skip IAM role

Skip S3 bucket

🧠 Interview-grade explanation (MEMORIZE)

“kOps runs production-grade Kubernetes on AWS using EC2, Auto Scaling, and ELB. It stores cluster state in S3 and requires sufficient memory for control-plane stability. Amazon Linux 2023 provides optimized AWS performance.”

🧹 Delete cluster (when done)

kops delete cluster $KOPS_CLUSTER_NAME --yes
aws s3 rb $KOPS_STATE_STORE --force


🧹 When finished (IMPORTANT to save cost)
kops delete cluster $KOPS_CLUSTER_NAME --yes
aws s3 rb $KOPS_STATE_STORE --force