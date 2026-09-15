# CPF-login Lambda infrastructure

This Terraform root is intentionally separate from the EKS stack. The CI/CD workflow validates it on every pull request and checks AWS before deployment. It applies this root only when the Lambda does not already exist, so an existing function is never imported, updated, or deleted by this root.

It needs an existing immutable JAR in S3 only for initial Lambda creation. After that, the Lambda repository CI/CD owns code updates with `aws lambda update-function-code`.
