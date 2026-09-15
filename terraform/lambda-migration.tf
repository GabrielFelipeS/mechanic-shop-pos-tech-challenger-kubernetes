# If an earlier revision of this stack was applied, remove its Lambda resources
# from this state without deleting the real AWS objects. Lambda provisioning now
# lives in the separate ../lambda Terraform root.
removed {
  from = aws_lambda_function.cpf_login

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_role.cpf_login_lambda

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_role_policy_attachment.cpf_login_lambda_basic_execution

  lifecycle {
    destroy = false
  }
}
