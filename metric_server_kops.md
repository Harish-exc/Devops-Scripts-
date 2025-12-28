Step 1: Download Metrics Server Manifest
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


This deploys the Metrics Server in the kube-system namespace.

Step 2: Patch Metrics Server for AWS

AWS nodes have self-signed kubelet certificates, and Metrics Server must communicate via InternalIP.

Edit the deployment:

kubectl -n kube-system edit deployment metrics-server


Locate this section in the YAML:

spec:
  template:
    spec:
      containers:
      - name: metrics-server
        args:
          - --cert-dir=/tmp
          - --secure-port=10250
          - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
          - --kubelet-use-node-status-port
          - --metric-resolution=15s


Update it to this:

args:
  - --cert-dir=/tmp
  - --secure-port=10250
  - --kubelet-insecure-tls                       # ADD THIS
  - --kubelet-preferred-address-types=InternalIP # MODIFY THIS
  - --kubelet-use-node-status-port
  - --metric-resolution=15s


--kubelet-insecure-tls allows Metrics Server to ignore self-signed kubelet certs.
--kubelet-preferred-address-types=InternalIP ensures it uses private IPs to reach nodes.

Step 3: Apply Changes

If you edited directly with kubectl edit, it’s already applied. If you created a patched YAML file:

kubectl apply -f metrics-server-patched.yaml


Then restart the deployment:

kubectl -n kube-system rollout restart deployment metrics-server

Step 4: Verify Metrics Server

Check if the Metrics Server pod is running:

kubectl -n kube-system get pods -l k8s-app=metrics-server -o wide


Expected output:

metrics-server-xxxxx   1/1   Running   0   1m

Step 5: Test Node Metrics

Once the pod is Running, test metrics:

kubectl top nodes
kubectl top pods --all-namespaces


You should now see CPU and memory usage.

Step 6 (Optional): Use HPA

Metrics Server enables Horizontal Pod Autoscaler:

kubectl autoscale deployment deployment-nginx --cpu-percent=50 --min=1 --max=3


Check HPA:

kubectl get hpa

✅ Key Notes for AWS / kOps

Metrics Server must use InternalIP; ExternalIP often fails.

If you only have 1 worker node, ensure topology spread constraints of pods (like CoreDNS) don’t prevent scheduling.

Control-plane nodes are usually tainted, so metrics server will not schedule there unless you remove the taint.