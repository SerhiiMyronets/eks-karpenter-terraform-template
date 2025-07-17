## Helm Charts Installation

After you create your infrastructure using the Terraform `render` module (step 1), the Helm `values.yaml` files are generated automatically and personalized for your environment. These files are stored in the `02-helm-charts/values` directory.

To install the required Helm charts:

1. **Navigate to the Helm directory:**

   ```bash
   cd 02-helm-charts
   ```

2. **Add Helm repositories and update them:**t

   ```bash
   helm repo add eks https://aws.github.io/eks-charts && \
   helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver && \
   helm repo add external-secrets https://charts.external-secrets.io && \
   helm repo add bitnami https://charts.bitnami.com/bitnami && \
   helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server && \
   helm repo update
   ```

3. **Install the charts:**

### Install AWS Load Balancer Controller

```bash
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --create-namespace \
  --version 1.7.1 \
  --values ./values/aws-load-balancer-controller-values.yaml
```

### Install AWS EBS CSI Driver

```bash
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --version 2.30.0 \
  --values ./values/aws-ebs-csi-driver-values.yaml
```

### Install External Secrets Operator

```bash
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --version 0.9.19 \
  --values ./values/external-secrets-values.yaml
```

### Install External DNS

```bash
helm upgrade --install external-dns bitnami/external-dns \
  --namespace external-dns \
  --create-namespace \
  --version 8.9.2 \
  --values ./values/external-dns-values.yaml
```

### Install Metrics Server

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --create-namespace \
  --version 3.12.1 \
  --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
```

### Install Karpenter

```bash
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --version v0.35.0 \
  --values ./values/karpenter-values.yaml
```