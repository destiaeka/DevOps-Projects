# Deploy an E-Commerce Three Tier Application on AWS EKS with Helm

![](https://miro.medium.com/v2/resize:fit:736/1*Ld1z5tAB6SP3Toq64MpExQ.png)

## Introduction

In the dynamic landscape of software development, architects and developers constantly seek robust design patterns that ensure scalability, maintainability, and efficient resource utilization. One such time-tested approach is the 3-tier architecture, a well-structured model that divides an application into three interconnected layers.

## Understanding the Basics

The 3-tier architecture is composed of three primary layers, each with distinct responsibilities:

**1. Presentation Layer**
- Also known as the user interface layer, this tier is responsible for interacting with end-users.
- It encompasses the user interface components, such as web pages, mobile apps, or any other interface through which users interact with the application.
- The goal is to provide a seamless and intuitive user experience while keeping the presentation logic separate from the business logic.

**2. Application (or Business Logic) Layer**
- Positioned between the presentation and data layers, the application layer contains the business logic that processes and manages user requests.
- It acts as the brain of the application, handling tasks such as data validation, business rules implementation, and decision-making.
- Separating the business logic from the presentation layer promotes code reusability, maintainability, and adaptability to changes.

**3. Data Layer**
- The data layer is responsible for managing and storing the application's data.
- It includes databases, data warehouses, or any other data storage solutions.
- This layer ensures data integrity, security, and efficient data retrieval for the application.

## Benefits of 3-Tier Architecture

**Scalability** — The modular nature allows independent scaling of each layer, enabling efficient resource allocation without affecting the entire application.

**Maintainability** — With clear separation of concerns, developers can make changes to one layer without impacting others, facilitating easier debugging and updates.

**Flexibility and Adaptability** — The architecture accommodates technology changes and updates without disrupting the entire system.

## Important Notes for AWS Academy Users

This project was deployed using an **AWS Academy** account, which has several IAM restrictions compared to a regular AWS account. The following steps from the original documentation could **not** be executed as written:

- **Step 2 (OIDC Provider)** — `iam:CreateOpenIDConnectProvider` is blocked. The OIDC provider cannot be created via CLI or console in AWS Academy.
- **Step 3 (ALB Add-On)** — `aws iam create-policy` and `eksctl create iamserviceaccount` are blocked, so the AWS Load Balancer Controller could not be fully installed.
- **Step 5 (EBS CSI Plugin)** — `eksctl create iamserviceaccount` is blocked, so the EBS CSI driver could not be installed. This caused the Redis PersistentVolumeClaim to remain in `Pending` state.

The workarounds applied are documented in each affected step below.

## Prerequisites

1. **kubectl** — A command line tool for working with Kubernetes clusters. [Install guide](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
2. **eksctl** — A command line tool for working with EKS clusters. [Install guide](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
3. **AWS CLI** — A command line tool for working with AWS services. [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
4. **Helm** — Package manager for Kubernetes. Installed in Step 5 below.

> **AWS Academy Note:** Credentials expire every ~4 hours. Before starting, go to AWS Academy → AWS Details → Show CLI credentials, and paste them into `~/.aws/credentials`.

---

## Steps

### Step 1: Create an EKS Cluster
![eks](/DevOps-Project-07/image/1.jpg)

### Step 2: Configure IAM OIDC Provider ⚠️ Skipped in AWS Academy

```bash
export cluster_name=cluster-ecommerce
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

# Check if OIDC provider already exists
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
```

If the output is empty, the OIDC provider needs to be created. However, in AWS Academy this command will fail with `AccessDenied`:

```bash
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
# Error: AccessDenied: not authorized to perform: iam:CreateOpenIDConnectProvider
```

> **AWS Academy Workaround:** This step is skipped. As a result, Step 3 (ALB Controller) and Step 5 (EBS CSI) also cannot be completed. The application is still accessible via the LoadBalancer service created automatically by EKS.

---

### Step 3: Setup ALB Add-On ⚠️ Skipped in AWS Academy

This step requires creating an IAM policy and IAM service account, both of which are blocked in AWS Academy. The ALB Controller is not installed.

> **AWS Academy Workaround:** The `aws-load-balancer-webhook` MutatingWebhookConfiguration left behind by a partial installation must be deleted before deploying the application, otherwise Helm will fail. This is handled in Step 7.

---

### Step 4: Install eksctl and Helm

**Install eksctl:**
```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

**Install Helm:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Update kubeconfig to connect kubectl to the cluster:**
```bash
aws eks update-kubeconfig --name cluster-ecommerce --region us-east-1
kubectl get nodes
```

---

### Step 5: EBS CSI Plugin ⚠️ Skipped in AWS Academy

This step requires `eksctl create iamserviceaccount`, which is blocked in AWS Academy. The EBS CSI driver is not installed, which causes Redis to fail to provision its PersistentVolumeClaim.

> **AWS Academy Workaround:** Redis is reconfigured to use `emptyDir` (in-memory storage) instead of a PersistentVolume. This is handled in Step 8.

---

### Step 6: Clone the Repository and Deploy with Helm

```bash
git clone https://github.com/uniquesreedhar/RobotShop-Project.git
cd RobotShop-Project/EKS/helm

# Create namespace
kubectl create ns robot-shop

# Delete the ALB webhook left behind from the partial ALB installation
# (required because ALB Controller is not running in AWS Academy)
kubectl delete mutatingwebhookconfiguration aws-load-balancer-webhook

# Install the Helm chart
helm install robot-shop --namespace robot-shop .
```

---

### Step 7: Verify Pods

```bash
kubectl get pods -n robot-shop
```

Most pods should be `Running`. Redis will be in `Pending` state because EBS CSI is not installed — fix this in the next step.

```
NAME                         READY   STATUS    RESTARTS   AGE
cart-7b8ddd675b-t2k9v        1/1     Running   0          4m5s
catalogue-6587b8998c-k5fsk   1/1     Running   0          4m5s
...
redis-0                      0/1     Pending   0          4m5s   ← fix in Step 8
```

---

### Step 8: Fix Redis — Replace PVC with emptyDir

Because EBS CSI is not available, Redis cannot provision a PersistentVolumeClaim. The fix is to replace the StatefulSet with one that uses `emptyDir` (ephemeral storage).

```bash
# Delete the stuck StatefulSet and PVC
kubectl delete statefulset redis -n robot-shop
kubectl delete pvc data-redis-0 -n robot-shop

# Create a new StatefulSet using emptyDir instead of PVC
cat <<EOF > redis-patch.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  namespace: robot-shop
spec:
  selector:
    matchLabels:
      service: redis
  serviceName: redis
  replicas: 1
  template:
    metadata:
      labels:
        service: redis
    spec:
      containers:
      - name: redis
        image: redis:4.0.6
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: data
          mountPath: /mnt/redis
      volumes:
      - name: data
        emptyDir: {}
EOF

kubectl apply -f redis-patch.yaml
```

Verify all pods are now running:

```bash
kubectl get pods -n robot-shop
```

All 12 pods should be `1/1 Running`.

---

### Step 9: Configure Ingress

```bash
cd RobotShop-Project/EKS/helm

# Delete the ALB validating webhook if it exists
kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook

# Apply ingress
kubectl apply -f ingress.yaml
```

> **Note:** In AWS Academy, the Ingress will not create an ALB because the ALB Controller is not running. The application is still accessible via the `web` service's LoadBalancer external IP (see Step 10).

---

### Step 10: Access the Application

Get the external LoadBalancer URL:

```bash
kubectl get svc web -n robot-shop
```

The `EXTERNAL-IP` column will show the ELB DNS name. Access the application at:

```
http://<EXTERNAL-IP>:8080
```

Example:
```
http://a401dfe164ee140928f4a9200e331c9b-542823717.us-east-1.elb.amazonaws.com:8080
```
![result](/DevOps-Project-07/image/2.jpg)

The RobotShop e-commerce application is now live. You can register, browse robots, add to cart, and place orders.

---

## Architecture Summary

```
Internet
   │
   ▼
ELB LoadBalancer (auto-created by EKS for service/web)
   │
   ▼
[Presentation Layer]
   web (Node.js frontend) — port 8080
   │
   ▼
[Application Layer]
   cart · catalogue · user · payment
   shipping · ratings · dispatch
   │
   ▼
[Data Layer]
   mongodb · mysql · redis · rabbitmq
```

---

## Congratulations!

Your 3-tier e-commerce application is successfully deployed on AWS EKS. 🎉