# retail_demo

Pet project: a retail data lakehouse on AWS built on the Olist Brazilian e-commerce dataset (2016–2018).

- `documents/datasets.md` — dataset schema and semantics
- `infra/aws/` — Terraform (S3 remote state, `use_lockfile` locking)


## Code style

- Avoid excessive comments. Don't restate what the code says; comment only non-obvious *why* (a constraint, a workaround, a surprising default).
