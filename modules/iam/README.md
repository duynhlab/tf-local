# IAM modules

Reusable patterns for `iam/*` lab roots.

| Module | Use case | Example roots |
|--------|----------|---------------|
| [irsa_role](./irsa_role/) | IAM role + optional inline policy | `iam/stg`, `iam/s3-eks` |
| [sqs_with_dlq](./sqs_with_dlq/) | SQS queue + DLQ (+ optional policy) | `iam/stg` |

Other roots keep composition in `main.tf` but should use `modules/lab-provider` for endpoints.
