# Bootstrap — remote state bucket

Apply once per AWS organization/account (local state for this stack only):

```bash
terraform init
terraform plan -var='state_bucket_name=YOUR-UNIQUE-terraform-state'
terraform apply -var='state_bucket_name=YOUR-UNIQUE-terraform-state'
```

Use the bucket in `envs/*/backend.tf` partial configuration.
