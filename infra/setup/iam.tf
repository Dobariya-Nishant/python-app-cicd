###################################################################
# Create IAM role and policies for Continuous Deploy (CD) account #
###################################################################

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "cd" {
  name = "recipe-app-api-cd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Dobariya-Nishant/python-app-cicd:ref:refs/heads/main",
              "repo:Dobariya-Nishant/python-app-cicd:ref:refs/heads/prod"
            ]
          }
        }
      }
    ]
  })
}


###########################################################
# Policy for Terraform backend to S3 and Dynamo DB access #
###########################################################

data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
    ]
    resources = [
      "arn:aws:dynamodb:us-east-1:*:table/tf-backend-lock"
    ]
  }
}

resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_role.cd.name}-tf-s3-dynamodb"
  description = "Allow IAM Role to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

resource "aws_iam_role_policy_attachment" "tf_backend" {
  role       = aws_iam_role.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn
}

#########################
# Policy for ECR access #
#########################

data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [
      aws_ecr_repository.app.arn,
      aws_ecr_repository.proxy.arn
    ]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_role.cd.name}-cd-ecr"
  description = "Allow IAM Role to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}

#########################
# Policy for VPC access #
#########################

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.cd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

#########################
# Policy for RDS access #
#########################

data "aws_iam_policy_document" "rds" {
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBInstances",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ListTagsForResource",
      "rds:ModifyDBInstance"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rds" {
  name        = "${aws_iam_role.cd.name}-rds"
  description = "Allow IAM Role to manage RDS resources."
  policy      = data.aws_iam_policy_document.rds.json
}

resource "aws_iam_role_policy_attachment" "rds" {
  role       = aws_iam_role.cd.name
  policy_arn = aws_iam_policy.rds.arn
}
