#!/bin/bash

set -euo pipefail

echo "🔄 Adding Helm repositories..."
helm repo add eks https://aws.github.io/eks-charts
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo add external-secrets https://charts.external-secrets.io
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server
helm repo update

echo "🚀 Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --create-namespace \
  --version 1.7.1 \
  --values ./values/aws-load-balancer-controller-values.yaml

echo "🚀 Installing AWS EBS CSI Driver..."
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --version 2.30.0 \
  --values ./values/aws-ebs-csi-driver-values.yaml

echo "🚀 Installing Metrics Server..."
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --create-namespace \
  --version 3.12.1 \
  --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"

echo "🚀 Installing Karpenter..."
helm install karpenter-crd oci://public.ecr.aws/karpenter/karpenter-crd --version 1.6.0
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --version 1.6.0 \
  --values ./values/karpenter-values.yaml

echo "🚀 Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --version 0.9.19 \
  --values ./values/external-secrets-values.yaml

echo "🚀 Installing External DNS..."
helm upgrade --install external-dns bitnami/external-dns \
  --namespace external-dns \
  --create-namespace \
  --version 8.9.2 \
  --values ./values/external-dns-values.yaml

echo "✅ All Helm charts installed successfully."