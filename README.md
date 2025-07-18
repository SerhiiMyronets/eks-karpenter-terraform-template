# Terraform Setup for EKS + Karpenter

A minimal and extensible infrastructure template for running Karpenter on AWS EKS with Spot instance support and Terraform-driven automation.

This repository provides a Terraform configuration for provisioning an EKS cluster and setting up [Karpenter](https://karpenter.sh) (v1.6.0) to manage dynamic compute capacity using both Spot and On-Demand EC2 instances.

It includes all essential AWS components like the VPC, IAM roles (with IRSA), and an SQS queue for handling Spot interruption events. Helm values and Kubernetes manifests are rendered automatically using gomplate based on Terraform outputs.

The goal is to keep the setup simple, reproducible, and aligned with how Karpenter is typically used in production environments.

### ✦ Features

* A fully automated EKS cluster setup with Terraform
* Karpenter configuration with support for Spot and On-Demand capacity
* Integration with SQS interruption queue to handle Spot instance terminations gracefully
* gomplate-powered rendering of manifests and Helm values
* Installation process designed to be GitOps-ready, with pre-rendered manifests and values that can be easily integrated into Argo CD or Flux workflows

---

## 📁 Repository Structure

```
.
├── 01-infra                # Terraform config for EKS and dependencies
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/            # Custom modules used in infrastructure setup
│       ├── 01-vpc/         # VPC, subnets, and routing
│       ├── 02-eks/         # EKS cluster and node group
│       ├── 03-sqs/         # SQS queue for interruption handling
│       └── 04-iam/         # IAM roles and policies for Karpenter
│
├── 02-render               # gomplate rendering logic
│   ├── render.sh           # Script to generate manifests and values
│   └── templates/          # Template files for gomplate
│
├── 03-install              # Final rendered output
│   ├── static-manifests/   # Sample NodePool with spot ec2 and test deployment
│   ├── helm-values/        # Rendered Helm values used for installation
│   └── rendered-manifests/ # Rendered core manifests (e.g., aws-auth, EC2NodeClass)
```

---

## ✦ Prerequisites

The following tools must be available in your environment:

* **Terraform** — for provisioning AWS infrastructure
* **AWS CLI** — used by Terraform and general access to AWS
* **kubectl** — to apply Kubernetes manifests and interact with the cluster
* **gomplate** — for rendering manifests and Helm values from templates
* **Helm** — to install Karpenter into the cluster

---

## ⚙️ Setup Instructions

### 1. Provision Infrastructure

#### terraform.tfvars

You don't need to create a `terraform.tfvars` file unless you want to override the default configuration. All variables have safe and low-cost defaults, but for customization (such as region, AZs, or instance types), an example file `terraform.tfvars.example` is provided.

💡 The defaults are optimized for learning, demos, and minimal AWS costs.


This step provisions all core AWS resources: VPC, subnets, Internet Gateway, IAM roles, SQS queue for Spot interruption handling, and the EKS cluster itself.

```bash
terraform init
terraform apply
```

Once complete, Terraform will produce a set of outputs that will be consumed by the next step.

Among the outputs, you will see a ready-to-run command for configuring your kubeconfig to access the cluster:

```bash
aws eks update-kubeconfig --region <<region>> --name <<cluster_name>>
```

This command is generated automatically based on your configuration.

---

### 2. Render Manifests

This step takes the Terraform outputs and uses them to generate environment-specific Kubernetes manifests and Helm values using gomplate.

```bash
cd ../02-render
bash render.sh
```

The rendered files will be placed into `03-install/static-manifests` and `03-install/helm-values`.

---

### 3. Apply and Install

#### Install Karpenter Helm chart

```bash
cd ../03-install

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter --create-namespace \
  --version 1.6.0 \
  -f ./helm-values/karpenter-values.yaml
```

#### Apply core infrastructure manifests

```bash
kubectl apply -f ./rendered-manifests/aws-auth-karpenter.yaml
```

This file grants the Karpenter controller access to join nodes via the `aws-auth` ConfigMap.

```bash
kubectl apply -f ./rendered-manifests/ec2-node-class.yaml
```

This defines the `EC2NodeClass` used by Karpenter to provision EC2 instances.

#### Apply example NodePool and test workload

```bash
kubectl apply -f ./static-manifests/node-pool-spot-example.yaml
```

This manifest defines a sample `NodePool` that uses Spot instances. It's a starting point for configuring how Karpenter should provision nodes.

```bash
kubectl apply -f ./static-manifests/test-deployment.yaml
```

This creates a simple test workload to trigger provisioning and verify that Karpenter is functioning as expected.

You can experiment by increasing the number of replicas in the deployment. Once the scheduled pods no longer fit on existing nodes, Karpenter will automatically provision new ones according to the configuration in the active `NodePool`.

---

## ✦ Testing the Interruption Queue

To verify that the Karpenter controller is correctly receiving Spot interruption warnings via SQS, you can manually send a test message using the AWS CLI.

To simplify testing, copy the actual queue URL and instance ARN from your environment and insert them into the following command:

```bash
aws sqs send-message \
  --queue-url "<your-queue-url>" \
  --message-body '{
    "version": "0",
    "id": "test-event-id-1",
    "detail-type": "EC2 Spot Instance Interruption Warning",
    "source": "aws.ec2",
    "account": "<your-account-id>",
    "time": "$(date -u -v+2M +\"%Y-%m-%dT%H:%M:%SZ\")",
    "region": "<your-region>",
    "resources": [
      "<your-instance-arn>"
    ],
    "detail": {
      "instance-id": "<your-instance-id>",
      "instance-action": "terminate"
    }
  }'
```

Use the list below to identify what values you need to provide:

- `<your-queue-url>` — full URL of the Karpenter interruption queue (from Terraform output or AWS Console)
- `<your-instance-arn>` — ARN of a Spot instance currently running (provisioned by Karpenter)
- `<your-instance-id>` — ID of the same Spot instance
- `<your-region>` — your AWS region (e.g. `us-east-1`)
- `<your-account-id>` — your AWS account ID

When the message is delivered, you should see logs from the Karpenter controller confirming receipt of the simulated interruption event. It will begin cordoning and draining the referenced node, followed by instance termination — mimicking the actual Spot interruption flow. After that, Karpenter will provision a replacement node if needed, based on the active `NodePool` settings.

---

## ✦ Cleanup Notes

Before destroying the infrastructure with Terraform, make sure that no Karpenter-managed nodes are still running in your cluster.

If any nodes remain (e.g., provisioned via `NodePool`), the corresponding EC2 instances can block deletion of related AWS resources such as security groups or IAM roles.

To avoid issues:

- Delete any active `NodePool` objects or scale them down to zero
- Ensure that all Karpenter-provisioned EC2 instances are terminated
- Wait for Kubernetes to fully remove the node objects from the cluster

Once the cluster is clean, you can safely run:

```bash
cd 01-infra
terraform destroy
```

---



## 📄 License

MIT © [Serhii Myronets](https://github.com/your-github-profile)
