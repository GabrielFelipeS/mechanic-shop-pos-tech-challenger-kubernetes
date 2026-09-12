# Kubernetes and observability infrastructure

- `terraform/`: tested AWS Academy EKS networking, cluster, nodes, EBS CSI, and optional New Relic Kubernetes bundle.
- `observability/`: New Relic dashboards, alert policies, notifications, and uptime monitoring.

Kubernetes application manifests are held in the Java application repository. Managed PostgreSQL is held in the database-infrastructure repository. The production-only GitHub Actions workflow validates both Terraform modules and applies them on pushes to `master`.
