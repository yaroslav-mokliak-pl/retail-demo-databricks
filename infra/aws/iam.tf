resource "aws_iam_role" "databricks_uc" {
  name = "databricks-uc-7474644734553598-retail-lakehouse"

  # Principals: Databricks UC master role + self-assume, required by UC storage credentials.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        AWS = [
          "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-uc-7474644734553598-retail-lakehouse",
        ]
      }
      Condition = {
        StringEquals = { "sts:ExternalId" = "905d6847-660f-47ae-88a9-18587577ac44" }
      }
    }]
  })

  tags = {
    DatabricksExternalBucket = aws_s3_bucket.databricks.bucket
  }

  lifecycle {
    prevent_destroy = true
    # Databricks-set boundary ARN uses account "partner", which the AWS provider's ARN validation rejects.
    ignore_changes = [permissions_boundary]
  }
}

resource "aws_iam_role_policy" "databricks_uc" {
  name = "databricks-ext-loc-access-policy-7474644734553598"
  role = aws_iam_role.databricks_uc.id

  # $${...} escapes Terraform interpolation; these are IAM policy variables resolved by AWS.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DatabricksS3DataAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
        ]
        Resource = [
          "arn:aws:s3:::$${aws:PrincipalTag/DatabricksExternalBucket}",
          "arn:aws:s3:::$${aws:PrincipalTag/DatabricksExternalBucket}/*",
        ]
        Condition = {
          StringEquals = { "s3:ResourceAccount" = "$${aws:PrincipalAccount}" }
        }
      },
      {
        Sid      = "AllowSelfAssumption"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-uc-7474644734553598-retail-lakehouse",
              "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL",
            ]
          }
        }
      },
      {
        Sid    = "ManagedFileEventsSetupAndTeardown"
        Effect = "Allow"
        Action = [
          "sns:ListSubscriptionsByTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:CreateTopic",
          "sns:TagResource",
          "sns:Publish",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:DeleteTopic",
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:TagQueue",
          "sqs:ChangeMessageVisibility",
          "sqs:PurgeQueue",
        ]
        Resource = [
          "arn:aws:sqs:*:*:csms-*",
          "arn:aws:sns:*:*:csms-*",
        ]
      },
      {
        Sid      = "ManagedFileEventsListStatement"
        Effect   = "Allow"
        Action   = ["sqs:ListQueues", "sqs:ListQueueTags", "sns:ListTopics"]
        Resource = "*"
      },
    ]
  })
}
