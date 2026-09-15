# Kubernetes infrastructure

Tested AWS Academy Terraform for the mechanic-shop EKS foundation: VPC, public node subnets, EKS, managed node group, EBS CSI add-on, NodePort ingress rules, and the optional New Relic Kubernetes bundle.

This module deliberately contains no application, Kong, Metrics Server, or PostgreSQL manifests. Those runtime manifests belong to the Java repository; PostgreSQL is provisioned only by the managed-database repository.

Kong invokes the CPF-login Lambda directly through the EKS node role; no API Gateway is provisioned. Lambda creation belongs to the sibling `lambda/` Terraform root, which the workflow runs only when the function is absent.
