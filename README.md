# Multi-Tenant Platform on AWS EKS

A production-ready, scalable multi-tenant platform deployed on Amazon EKS (Elastic Kubernetes Service) designed for small to medium-sized enterprises running microservices, SaaS applications, and internal tools.

## 📋 Overview

This project provides a complete infrastructure-as-code solution for deploying a secure, observable, and scalable multi-tenant application on AWS EKS. It addresses common challenges faced by SMEs:

- **Automated deployments** - Eliminate manual errors and ensure consistent releases
- **Environment isolation** - Clear separation between dev/stage/prod environments
- **Observability** - Built-in logging and monitoring via CloudWatch
- **Security** - Secrets management using AWS Secrets Manager, network policies, and encrypted communication
- **Auto-scaling** - Horizontal Pod Autoscaler (HPA) and Cluster Autoscaler for handling traffic spikes
- **DNS automation** - Automatic DNS record management with ExternalDNS

## 🏗️ Architecture

### AWS Infrastructure
- **VPC** - Public and private subnets for network isolation
- **EKS Cluster** - Kubernetes cluster with multiple node groups
  - `system-ng` - System components (CoreDNS, Ingress Controller, ExternalDNS, Cert-Manager)
  - `apps-ng` - Application workloads
- **ECR** - Container image registry
- **RDS PostgreSQL** - Managed relational database
- **Route 53** - DNS management
- **CloudWatch** - Logs and Container Insights monitoring
- **ACM** - SSL/TLS certificates for HTTPS

### Kubernetes Components
- **Namespaces** - Separate environments (dev, stage, prod)
- **Ingress Controller** - AWS Load Balancer Controller or NGINX
- **ExternalDNS** - Automatic DNS record creation
- **Network Policies** - Namespace isolation and security controls
- **HPA** - Horizontal Pod Autoscaler
- **Cluster Autoscaler** - Dynamic node scaling
- **Secrets Management** - AWS Secrets Manager integration with External Secrets Operator
- **Monitoring** - CloudWatch for metrics and logs

### Application Services
- **API** - Python/Node.js REST API service
- **Frontend** - Web application frontend served via NGINX
- **Worker** - Asynchronous task processor with Celery
- **Redis** - In-memory cache and message broker
- **Database** - PostgreSQL for persistent storage

## 📁 Project Structure

```
.
├── README.md                      # Project documentation (this file)
├── .gitignore                    # Git ignore rules
├── 
├── app/                          # Helm Chart for Kubernetes deployment
│   ├── Chart.yaml               # Chart metadata
│   ├── .helmignore              # Helm ignore rules
│   ├── values.yaml              # Default Helm values
│   ├── values-dev.yaml          # Development environment values
│   ├── templates/               # Kubernetes manifests
│   │   ├── api.yml             # API service deployment
│   │   ├── frontend.yml        # Frontend deployment
│   │   ├── worker.yml          # Worker deployment
│   │   ├── redis.yml           # Redis cache
│   │   ├── ingress-lb.yml      # Ingress controller
│   │   ├── configmap-*.yml     # ConfigMaps for services
│   │   ├── db-aws-secret-provider.yml  # Database secrets
│   │   └── network-policy-*.yml  # Network security policies
│   └── charts/                  # Helm dependencies
│
├── infra/                        # Terraform Infrastructure as Code
│   ├── terraform.tfstate        # Local state file
│   ├── envs/
│   │   └── dev/                 # Development environment terraform
│   │       ├── main.tf          # Main infrastructure config
│   │       ├── variables.tf     # Variable definitions
│   │       ├── outputs.tf       # Output values
│   │       └── terraform.tfstate # State file
│   ├── modules/                 # Reusable terraform modules
│   │   ├── vpc/                # Virtual Private Cloud
│   │   ├── eks/                # EKS cluster setup
│   │   ├── ecr/                # Container registry
│   │   ├── rds/                # Database configuration
│   │   └── cert/               # SSL certificates
│   ├── k8s-bootstrap/          # Initial K8s setup
│   │   ├── aws-load-balancer-controller.tf
│   │   ├── aws-external-dns.tf
│   │   ├── csi-secrets-store.tf
│   │   ├── vpc-cni.tf
│   │   ├── cloudwatch-metrics.tf
│   │   ├── metrics-server.tf
│   │   ├── providers.tf
│   │   ├── data.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfstate
│   │   └── policies/
│   │       └── iam_policy.json  # IAM policies
│   └── remote-backend-bootstrap/ # Remote state backend setup
│
└── myapp/                        # Application source code
    ├── .dockerignore            # Docker build ignore rules
    ├── api/                     # REST API service
    │   ├── Dockerfile
    │   ├── requirements.txt      # Python dependencies
    │   └── app/
    │       ├── main.py         # FastAPI/Flask main app
    │       ├── celery_app.py   # Celery worker setup
    │       ├── db_dsn.py       # Database connection
    │       ├── healthchecks.py # Readiness/liveness probes
    │       ├── logging_config.py
    │       └── __init__.py
    ├── frontend/               # Web application
    │   ├── Dockerfile
    │   ├── nginx.conf          # NGINX configuration
    │   ├── entrypoint.sh       # Container startup script
    │   └── html/
    │       ├── index.html      # Main page
    │       ├── app.js         # Frontend logic
    │       └── config.template.js
    └── worker/                 # Async task processor
        ├── Dockerfile
        ├── entrypoint.sh
        ├── requirements.txt
        └── app/
            ├── worker.py      # Celery task definitions
            ├── logging_config.py
            └── __init__.py
```

## 🚀 Getting Started

### Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.0
- **kubectl** >= 1.24
- **Helm** >= 3.0
- **Docker** for building container images
- **AWS CLI** configured with credentials

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Multi-tenant-Platform-on-EKS
   ```

2. **Set AWS credentials**
   ```bash
   export AWS_REGION=us-east-1
   export AWS_PROFILE=your-aws-profile
   ```

3. **Initialize remote backend** (optional but recommended)
   ```bash
   cd infra/remote-backend-bootstrap
   terraform init
   terraform apply
   cd ../..
   ```

4. **Deploy infrastructure**
   ```bash
   cd infra/envs/dev
   terraform init
   terraform plan
   terraform apply
   cd ../../..
   ```

5. **Configure kubectl access**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name eks-cluster-test-dev-us-east-1
   ```

6. **Deploy Kubernetes bootstrap components**
   ```bash
   cd infra/k8s-bootstrap
   terraform init
   terraform apply
   cd ../..
   ```

7. **Build and push container images**
   ```bash
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 326306382233.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and push API image
   docker build -t myapp-api:latest ./myapp/api
   docker tag myapp-api:latest 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-api-image:latest
   docker push 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-api-image:latest
   
   # Build and push Frontend image
   docker build -t myapp-frontend:latest ./myapp/frontend
   docker tag myapp-frontend:latest 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-frontend-image:latest
   docker push 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-frontend-image:latest
   
   # Build and push Worker image
   docker build -t myapp-worker:latest ./myapp/worker
   docker tag myapp-worker:latest 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-worker-image:latest
   docker push 326306382233.dkr.ecr.us-east-1.amazonaws.com/repo-worker-image:latest
   ```

8. **Deploy applications with Helm**
   ```bash
   cd app
   helm dependency update
   helm install myapp . -f values-dev.yaml -n dev --create-namespace
   cd ..
   ```

9. **Verify deployment**
   ```bash
   kubectl get pods -n dev
   kubectl get services -n dev
   kubectl get ingress -n dev
   ```

## 🔒 Security Features

- **Secrets Management** - Uses AWS Secrets Manager with External Secrets Operator
- **Network Policies** - Restricts traffic between namespaces and pods
- **IAM Roles** - Service accounts with fine-grained permissions
- **RBAC** - Kubernetes role-based access control
- **TLS/HTTPS** - Automatic certificate management with ACM
- **Encrypted Communication** - Secure pod-to-pod communication

## 📊 Monitoring & Logging

### CloudWatch Integration
- **Container Insights** - EKS container monitoring
- **CloudWatch Logs** - Centralized logging
- **Metrics** - CPU, memory, network monitoring

### Application Logs
- API logs
- Worker logs
- Frontend access logs

Access logs in CloudWatch console or via CLI:
```bash
aws logs tail /aws/eks/dev/api --follow
aws logs tail /aws/eks/dev/worker --follow
```

## 🔄 CI/CD Integration

The project is designed to integrate with CI/CD pipelines:

1. Build Docker images in your CI system
2. Push to ECR
3. Update Helm values with new image tags
4. Deploy with `helm upgrade`

Example workflow for development:
```bash
# On code push
docker build -t repo-api-image:$GIT_COMMIT ./myapp/api
docker push $ECR_REGISTRY/repo-api-image:$GIT_COMMIT
helm upgrade myapp ./app -f values-dev.yaml --set image.tag=$GIT_COMMIT
```

## 📈 Scaling

### Auto Scaling Policies

The cluster supports multiple scaling mechanisms:

- **Horizontal Pod Autoscaler (HPA)** - Scales pods based on CPU/memory
- **Cluster Autoscaler** - Adds nodes when pods can't be scheduled
- **Manual Scaling** - Adjust replica count or node group size

Check HPA status:
```bash
kubectl get hpa -n dev
```

## 🔧 Configuration

### Environment-Specific Values

- `app/values.yaml` - Production defaults
- `app/values-dev.yaml` - Development overrides

Customize:
- Replica counts
- Resource limits
- Environment variables
- Ingress hostname
- Database credentials

### Terraform Variables

Edit `infra/envs/dev/terraform.tfvars`:
```hcl
region              = "us-east-1"
cluster_name        = "eks-cluster-test-dev-us-east-1"
node_group_name     = "apps-ng"
desired_size        = 2
max_size            = 5
min_size            = 1
instance_types      = ["t3.medium"]
```

## 🛠️ Troubleshooting

### Check Cluster Status
```bash
kubectl get nodes
kubectl get namespaces
kubectl describe node <node-name>
```

### View Pod Logs
```bash
kubectl logs -n dev deployment/api
kubectl logs -n dev deployment/worker
kubectl logs -n dev deployment/frontend
```

### Check Events
```bash
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Describe Resources
```bash
kubectl describe pod -n dev <pod-name>
kubectl describe service -n dev <service-name>
```

### Common Issues

**Pods stuck in Pending:**
```bash
kubectl describe pod -n dev <pod-name>  # Check events for details
kubectl top nodes                        # Check node resources
```

**ImagePullBackOff:**
```bash
# Verify ECR credentials and image tags
aws ecr describe-repositories
aws ecr list-images --repository-name repo-api-image
```

**DNS resolution issues:**
```bash
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -n dev -- bash
nslookup kubernetes.default.svc.cluster.local
```

## 📝 Documentation

This project includes comprehensive documentation for deployment and management:

- **Helm Chart** - Located in `app/` directory with customizable values for different environments
- **Terraform Modules** - Infrastructure as Code in `infra/` for reproducible deployments
- **Docker Images** - Application containerization in `myapp/` with optimized configurations

## 🤝 Contributing

1. Create a feature branch
2. Make changes to infrastructure or application code
3. Test in dev environment
4. Submit pull request for review
5. Deploy to stage after approval
6. Deploy to prod after stage validation


## 📧 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS EKS documentation
3. Contact the platform team

---

**Last Updated:** March 2026
**Kubernetes Version:** 1.24+
**Terraform Version:** 1.0+
**AWS Region:** us-east-1
