# EKS + Karpenter Terraform Template

Terraform-based template for deploying a production-ready AWS EKS cluster integrated with [Karpenter](https://karpenter.sh) (v1.6.0), using a modular and flexible structure.

This setup is focused on **hybrid node provisioning** with **Spot and On-Demand** capacity, following infrastructure-as-code best practices.

## 📁 Project Structure

```
├── 01-infra           # Terraform modules for EKS, IAM, VPC, Karpenter, etc.
│   ├── modules        # Reusable Terraform modules
│   ├── main.tf        # Cluster composition
│   └── outputs.json   # Terraform output exported for rendering
├── 02-render          # Render stage: gomplate templates for config
│   ├── templates      # *.gotmpl templates using terraform outputs
│   └── render.sh      # Script to render templates into 03-install
├── 03-install         # Rendered Karpenter CRDs and Helm values for installation
│   ├── manifests      # ConfigMap, EC2NodeClass, etc.
│   └── values         # Helm values (e.g., karpenter-values.yaml)
└── README.md          # This file
```

---

## Prerequisites

Before using this template, ensure the following are installed:

* **Terraform** `>= 1.4`
* **AWS CLI** configured with sufficient permissions (IAM, EKS, SQS, EC2)
* **kubectl** and access to apply changes to your cluster
* **gomplate** for rendering YAML files based on Terraform outputs (`brew install gomplate`)

You must also have a Route53 hosted zone in your AWS account for service discovery.

---

## Setup Instructions

### Step 1: Provision EKS Infrastructure

```bash
cd 01-infra
terraform init
terraform apply
```

After Terraform finishes, export the outputs to JSON:

```bash
terraform output -json > ../02-render/outputs.json
```

### Step 2: Render Karpenter Manifests

```bash
cd ../02-render
bash render.sh
```

This will use `gomplate` to render manifests into `../03-install/`.

### Step 3: Apply Manifests and Install Karpenter

```bash
cd ../03-install
kubectl apply -f ./manifests

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter --create-namespace \
  --version 1.6.0 \
  -f ./values/karpenter-values.yaml
```

---

## Why Not GitOps?

This repo intentionally avoids GitOps (e.g. Argo CD, Flux) to retain full manual control over:

* Karpenter provisioning templates
* Helm values and node class configuration
* Simple experimentation and prototyping

You can easily extend or adapt this project to GitOps later.

---

## Future Extensions

* Add custom `NodePool` examples (On-Demand, Spot-only, GPU, etc.)
* Add monitoring (e.g., kube-prometheus-stack)
* Add ALB controller and TLS certificates

---

## License

MIT © Serhii Myronets
