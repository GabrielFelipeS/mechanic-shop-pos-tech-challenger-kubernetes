# Infraestrutura Kubernetes e observabilidade

Repositório de infraestrutura do Tech Challenge - Fase 3. Ele provisiona a base AWS da aplicação: rede, cluster EKS, nós gerenciados, add-on EBS CSI, permissões de implantação, integração da Lambda de login por CPF e recursos de observabilidade no New Relic.

## Arquitetura

```mermaid
flowchart TB
  I[Terraform: terraform/] --> V[VPC e sub-redes]
  I --> E[EKS e managed node group]
  I --> R[IAM, EBS CSI e regras NodePort]
  I --> P[Permissões para deploy da aplicação]
  L[Terraform: lambda/] --> F[Lambda CPF Login]
  O[Terraform: observability/] --> N[New Relic: dashboards, alertas e synthetics]
  E --> A[Aplicação e Kong\n(manifests no repositório da API)]
  A --> F
  A --> N
```

Os manifests de runtime da aplicação, Kong e Metrics Server ficam no repositório da API. O PostgreSQL RDS fica no repositório de banco gerenciado; por isso este projeto não cria banco nem aplica manifests da aplicação.

## Estrutura

- `terraform/`: VPC, EKS, nodes, IAM, EBS CSI e integração com a Lambda existente;
- `lambda/`: criação inicial da Lambda e permissões, caso ela ainda não exista;
- `observability/`: dashboards, alertas, notificações e monitoramento de disponibilidade no New Relic.

## Pré-requisitos

Terraform, AWS CLI autenticada, permissões para criar recursos AWS e, após criar o cluster, `kubectl`. Use uma conta/projeto AWS autorizado; os valores de estado remoto e segredos não devem ser commitados.

## Provisionamento básico

Copie o arquivo de exemplo e preencha os valores exigidos, especialmente `app_deployer_role_arn`:

```bash
cd terraform
copy terraform.tfvars.example terraform.tfvars
terraform init -backend-config="bucket=<BUCKET_DE_ESTADO>" -backend-config="key=mechanic-shop/eks.tfstate" -backend-config="region=sa-east-1"
terraform plan
terraform apply
```

No PowerShell, `copy` pode ser substituído por `Copy-Item`. Após o apply, configure o acesso ao cluster com o comando exposto em `terraform output -raw kubeconfig_command` e confirme com `kubectl get nodes`.

Para criar a Lambda somente quando necessário, execute os mesmos comandos dentro de `lambda/`, após disponibilizar o JAR inicial no S3 conforme as variáveis do módulo. Para observabilidade, copie `observability/terraform.tfvars.example`, informe a chave do New Relic e execute `terraform init`, `plan` e `apply` em `observability/`.

## Integrações e documentação

Depois de provisionar, entregue ao repositório de banco os outputs `vpc_id`, `vpc_cidr` e `private_subnet_ids`. Em seguida, implante os manifests da aplicação no cluster. A API é documentada no [Swagger da aplicação](http://localhost:8080/swagger-ui.html) em ambiente local; em nuvem, use o host público do Kong com o mesmo caminho.

Este checkout não contém workflow de CI/CD versionado. Para cumprir a fase, configure pipeline com `fmt`, `validate` e `plan` em pull requests e `apply` controlado nas branches de homologação/produção, usando backend remoto e credenciais OIDC.
