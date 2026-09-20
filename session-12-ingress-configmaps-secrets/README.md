# Session 12: Kubernetes Ingress, ConfigMaps & Secrets

## Table of Contents

1. [ConfigMap — Decoupling Plain-Text Configuration](#configmap--decoupling-plain-text-configuration)
2. [Secret — Protecting Sensitive Credentials](#secret--protecting-sensitive-credentials)
3. [Ingress — One Entry Point for All Microservices](#ingress--one-entry-point-for-all-microservices)
4. [Full Demo — ConfigMap + Secret + Ingress Working Together](#full-demo--configmap--secret--ingress-working-together)
5. [Hands-on Lab Exercises](#hands-on-lab-exercises)
6. [Troubleshooting Notes](#troubleshooting-notes)

---

## ConfigMap — Decoupling Plain-Text Configuration

### Why Do We Need ConfigMap?

**The Problem:** Configuration baked into Docker images

```
Image: v1 (LOG=DEBUG)
Image: v2 (LOG=INFO)
Image: v3 (PORT=8080)
```

If configuration is baked into the image, you must **rebuild the Docker image every time a config value changes**.

**The Solution:** ConfigMap

```
ConfigMap: LOG=INFO, PORT=5000
Same image deployed everywhere!
```

### Important Points

- ConfigMaps are for **non-sensitive** data only (log levels, port numbers, feature flags, API base URLs).
- Never store passwords, tokens, or certificates in a ConfigMap.
- ConfigMaps can be consumed as **environment variables** (`envFrom`) or **mounted as files** inside a container.
- Updating a ConfigMap does NOT automatically restart your pods. Pods must be restarted to pick up new values.
- ConfigMaps have a size limit of **1 MiB**.

### Real-World Use Cases

- Storing `LOG_LEVEL`, `ENVIRONMENT` (dev/staging/prod), `CACHE_TTL`, `MAX_CONNECTIONS`
- Mounting an entire Nginx `nginx.conf` file into a pod via a ConfigMap volume
- Passing feature-flag toggles (`FEATURE_DARK_MODE: "true"`) without rebuilding images

### Code: configmap/app-config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
  labels:
    app: yatri-backend
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
  PORT: "5000"
  DEFAULT_CURRENCY: "INR"
  MAX_BOOKING_DAYS: "30"
```

### Apply and Inspect

```bash
kubectl apply -f configmap/app-config.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
```

**Screenshot:**
![ConfigMap Task](./screenshot/01-configmap.png)

---

## Secret — Protecting Sensitive Credentials

### Why Do We Need Secrets?

**The Problem:** Passwords stored in plain text or baked into images

```python
# BAD: Password baked into code and leaked in git history
DB_PASSWORD = "superSecretPwd123"
```

**The Solution:** Kubernetes Secret

```
Raw value:    secretpassword
Base64 value: c2VjcmV0cGFzc3dvcmQ=
```

### Important Points

- **Base64 is NOT encryption.** It is encoding. Anyone with RBAC access can decode it.
- For production, use **external secret managers** (AWS Secrets Manager, HashiCorp Vault).
- Always use `echo -n` when base64-encoding values.
- Secrets can be injected as environment variables or as **files mounted into a volume**.
- Enable **encryption at rest** for `etcd` in production clusters.

### Real-World Use Cases

- Database credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`)
- API keys and OAuth client secrets
- TLS certificate (`tls.crt`) and private key (`tls.key`)
- Docker Hub / ECR image pull credentials

### Code: secret/db-secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
  labels:
    app: yatri-backend
type: Opaque
data:
  POSTGRES_USER: eWF0cmlfYWRtaW4=
  POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=
  POSTGRES_DB: eWF0cmlfcHJvZHVjdGlvbl9kYg==
```

### Generate Base64 Values

```bash
echo -n "yatri_admin" | base64
# Output: eWF0cmlfYWRtaW4=

echo -n "secretpassword" | base64
# Output: c2VjcmV0cGFzc3dvcmQ=
```

### Apply and Inspect

```bash
kubectl apply -f secret/db-secret.yaml
kubectl get secret yatri-db-secret
```

**Screenshot:**
![Secret Task](./screenshot/02-secret.png)

---

## Ingress — One Entry Point for All Microservices

### Why Do We Need Ingress?

**Without Ingress:**

```
Frontend     -> AWS Load Balancer 1 ($25/month)
Backend API  -> AWS Load Balancer 2 ($25/month)
Auth         -> AWS Load Balancer 3 ($25/month)
Total: $75/month just for load balancers
```

**With Ingress:**

```
1 AWS Load Balancer ($25/month)
     |
NGINX Ingress Controller
     |
     +-- yatri.local/         -> Frontend
     +-- yatri.local/api/*    -> Backend API
```

### Important Points

- An `Ingress` resource is **just a routing rule definition**. It does nothing on its own.
- You MUST have an **Ingress Controller** installed in your cluster (e.g., `ingress-nginx`).
- Ingress operates at **Layer 7 (HTTP/HTTPS)**. It can route based on hostnames and URL paths.
- Ingress supports **TLS/HTTPS termination**.
- On Minikube, enable the addon: `minikube addons enable ingress`.

### Real-World Use Cases

- Routing `app.company.com` to frontend and `api.company.com` to backend from a single IP
- SSL/TLS termination without modifying application code
- Canary deployments with traffic splitting
- Centralized rate limiting, authentication, and CORS

### Code: ingress/ingress-routes.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
    - host: yatri.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
```

### Apply and Inspect

```bash
kubectl apply -f ingress/ingress-routes.yaml
kubectl get ingress yatri-ingress
kubectl describe ingress yatri-ingress
```

**Screenshot:**
![Ingress Task](./screenshot/03-ingress.png)

---

## Full Demo — ConfigMap + Secret + Ingress Working Together

### What This Demo Does

This demo deploys two microservices behind a single NGINX Ingress:

- **Frontend** (`/`) — Nginx serving HTML, reads config from ConfigMap
- **Backend API** (`/api/`) — Python HTTP server, reads ConfigMap + Secret

```
Your Browser
     |
     | http://yatri.local/       --> Frontend (Nginx)
     | http://yatri.local/api/   --> Backend  (Python API)
     v
NGINX Ingress Controller (path-based routing)
```

### Architecture: File Purposes

| File             | Kind                 | Purpose                                        |
| ---------------- | -------------------- | ---------------------------------------------- |
| `configmap.yaml` | ConfigMap            | 5 non-sensitive config values                  |
| `secret.yaml`    | Secret               | Base64-encoded database credentials            |
| `frontend.yaml`  | Deployment + Service | Nginx frontend, reads ConfigMap                |
| `backend.yaml`   | Deployment + Service | Python API, reads ConfigMap + Secret           |
| `ingress.yaml`   | Ingress              | Routes `/api/*` to backend and `/` to frontend |
| `run-demo.sh`    | Shell Script         | One-command full deploy                        |
| `cleanup.sh`     | Shell Script         | Removes all created resources                  |

### Architecture: Traffic Flow

```
Public Internet
     |
     | https://yatri.local (Port 80/443)
     v
+------------------------------------------+
|   NGINX Ingress Controller Pod           |
|   (Layer 7 HTTP Reverse Proxy)           |
+------------------------------------------+
     |                        |
     | Path: /                | Path: /api/*
     v                        v
+----------------+     +---------------------+
| Frontend Svc   |     | Backend API Svc      |
| (ClusterIP)    |     | (ClusterIP)          |
+----------------+     +---------------------+
```

### Prerequisites

```bash
minikube status
kubectl config current-context
# Expected output: minikube
```

### Step-by-Step Manual Run

#### Step 1: Enable NGINX Ingress Addon

```bash
minikube addons enable ingress
```

#### Step 2: Apply ConfigMap

```bash
kubectl apply -f configmap.yaml
kubectl describe configmap yatri-app-config
```

#### Step 3: Apply Secret

```bash
kubectl apply -f secret.yaml
kubectl describe secret yatri-db-secret
```

#### Step 4: Deploy Frontend

```bash
kubectl apply -f frontend.yaml
kubectl get pods -l app=yatri-frontend
```

#### Step 5: Deploy Backend

```bash
kubectl apply -f backend.yaml
kubectl rollout status deployment/yatri-backend
```

#### Step 6: Apply Ingress

```bash
kubectl apply -f ingress.yaml
kubectl describe ingress yatri-ingress
```

#### Step 7: Add yatri.local to /etc/hosts

```bash
echo "$(minikube ip)  yatri.local" | sudo tee -a /etc/hosts
```

### Testing

```bash
# Test Frontend (at root path /)
curl http://yatri.local

# Test Backend API (at /api/)
curl http://yatri.local/api/
```

Expected Backend Output:

```
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
```

### One-Command Automated Deploy

```bash
bash run-demo.sh
```

### Cleanup

```bash
bash cleanup.sh
```

### Screenshot: Demo 1

![Full Demo 1](./screenshot/4demo-1.png)

### Screenshot: Demo 2

![Full Demo 2](./screenshot/4demo-2.png)

### Screenshot: Demo 3

![Full Demo 3](./screenshot/4demo-3.png)

### Screenshot: Demo 4

![Full Demo 4](./screenshot/4demo-4.png)

### Screenshot: Demo 5

![Full Demo 5](./screenshot/4demo-5.png)

---

## Hands-on Lab Exercises

### Part 1: ConfigMap

#### Read and Apply

```bash
cat configmap.yaml

kubectl apply -f configmap.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
```

#### Read a specific key

```bash
kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'
```

### Part 2: Secret

#### The newline bug

```bash
# Wrong way — adds trailing newline
echo "mypassword" | base64

# Correct way
echo -n "mypassword" | base64
```

#### Apply and verify

```bash
cat secret.yaml

kubectl apply -f secret.yaml
kubectl get secret yatri-db-secret

# Notice values are masked
kubectl describe secret yatri-db-secret

# Decode the password
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
```

### Part 3: Deploy Backend

#### Apply backend

```bash
kubectl apply -f backend.yaml
```

#### Verify environment variables

```bash
kubectl exec -it deployment/yatri-backend -- env | grep -E "ENVIRONMENT|LOG_LEVEL|POSTGRES"
```

### Part 4: Deploy Frontend

```bash
kubectl apply -f frontend.yaml
kubectl get pods -l app=yatri-frontend
```

### Part 5: Ingress

#### Enable NGINX Ingress Controller

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

#### Apply Ingress

```bash
cat ingress.yaml

kubectl apply -f ingress.yaml
kubectl get ingress yatri-ingress
```

### Part 6: Test Routing

```bash
INGRESS_IP=$(minikube ip)

# Test Root path — Frontend
curl -s -H "Host: yatri.local" http://${INGRESS_IP}/

# Test API path — Backend
curl -s -H "Host: yatri.local" http://${INGRESS_IP}/api/
```

### Part 8: The Newline Bug

```bash
# Wrong way
echo "secretpassword" | base64
# Output ends in Ao=

# Correct way
echo -n "secretpassword" | base64
# Output ends cleanly in =
```

### Part 9: Update ConfigMap

```bash
# Patch ConfigMap live
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'

# Check pod - values won't change (env vars set at startup)
kubectl exec -it deployment/yatri-backend -- env | grep ENVIRONMENT

# Trigger rolling restart
kubectl rollout restart deployment/yatri-backend
kubectl rollout status deployment/yatri-backend

# Now value is updated
kubectl exec -it deployment/yatri-backend -- env | grep ENVIRONMENT
```

### Automation Screenshots

**Screenshot: Automation 1**
![Automation 1](./screenshot/automation1.png)

**Screenshot: Automation 2**
![Automation 2](./screenshot/automation2.png)

---

## Troubleshooting Notes

### Secret Base64 Gotcha

**Problem:** Base64 encoding with `echo` adds a trailing newline character, causing authentication failures.

**Wrong Way:**

```bash
echo "secretpassword" | base64
# Output: c2VjcmV0cGFzc3dvcmQK  (ends with Ao= - the K encodes \n)
```

**Correct Way:**

```bash
echo -n "secretpassword" | base64
# Output: c2VjcmV0cGFzc3dvcmQ=  (clean ending)
```

**Solution:** Always use `echo -n` when encoding secrets for Kubernetes.

---

## Key Interview Points

### ConfigMap vs Secret

| Feature            | ConfigMap     | Secret                    |
| ------------------ | ------------- | ------------------------- |
| Data Type          | Non-sensitive | Sensitive                 |
| Storage            | Plain text    | Base64 encoded            |
| RBAC Protection    | No            | Yes                       |
| Encryption at Rest | No            | Yes (requires enablement) |

### Ingress Key Points

- **IngressClassName: nginx** - Required field specifying which Ingress Controller handles the rule
- **rewrite-target** - Strips path prefixes before forwarding to backend services
- **ssl-redirect** - Forces HTTPS redirection

### Environment Variable Injection

- **envFrom** - Injects all ConfigMap keys at once
- **secretKeyRef** - Injects individual Secret keys one by one
- Values are set at container startup; pods must be restarted to pick up changes

---

## File Structure

```
session-12-ingress-configmaps-secrets/
├── README.md
├── screenshot/
│   ├── 01-configmap.png
│   ├── 02-secret.png
│   ├── 03-ingress.png
│   ├── 4demo-1.png
│   ├── 4demo-2.png
│   ├── 4demo-3.png
│   ├── 4demo-4.png
│   ├── 4demo-5.png
│   ├── automation1.png
│   └── automation2.png
├── 01-configmap/
│   ├── app-config.yaml
│   └── README.md
├── 02-secret/
│   ├── db-secret.yaml
│   └── README.md
├── 03-ingress/
│   ├── ingress-routes.yaml
│   ├── ingress-tls.yaml
│   ├── tls.key
│   ├── tls.crt
│   └── README.md
└── 04-full-demo/
    ├── configmap.yaml
    ├── secret.yaml
    ├── frontend.yaml
    ├── backend.yaml
    ├── ingress.yaml
    ├── run-demo.sh
    ├── cleanup.sh
    └── README.md
```
