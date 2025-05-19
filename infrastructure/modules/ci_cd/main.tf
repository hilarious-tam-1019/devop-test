// IAM Roles & Policies

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role-${var.name}-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })
}

# CodeDeploy IAM Policy
resource "aws_iam_role_policy" "codedeploy_policy" {
  role = aws_iam_role.codedeploy_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "*"
      },
      # Allow CodeDeploy to interact with EC2 instances (for EC2 deployment)
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstanceStatus"
        ],
        Resource = "*"
      },
      # Allow CodeDeploy to manage deployments in the deployment group
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:CreateDeploymentConfig",
          "codedeploy:GetDeployment",
          "codedeploy:ListDeployments",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:PutLifecycleEventHookExecutionStatus"
        ],
        Resource = "*"
      },
      # Allow CodeDeploy to interact with CloudWatch Logs for logging
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      # Allow CodeDeploy to use KMS keys (for encryption if needed)
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:*",
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
      },

    ]
  })
}

# CodePipeline IAM Role
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role-${var.name}-${terraform.workspace}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

# CodePipeline IAM Policy (S3 + CodeStar permissions)
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection",
          "codestar-connections:DescribeConnection"
        ],
        Resource = var.codestar_connection_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:*",
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "codedeploy:*",
        ],
        Resource = [
          "arn:aws:codedeploy:ap-southeast-1:026090549419:*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:StopBuild"
        ],
        Resource = flatten([
          for key in keys(var.services) : [
            aws_codebuild_project.push[key].arn,
            aws_codebuild_project.scan[key].arn
          ]
        ])
      }
    ]
  })

  depends_on = [aws_codebuild_project.push, aws_codebuild_project.scan]
}

# CodeBuild IAM Roles (one per service)
resource "aws_iam_role" "codebuild_role" {
  for_each = var.services
  name     = "codebuild-role-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

# CodeBuild IAM Policies (ECR + Logs/S3 permissions)
resource "aws_iam_role_policy" "codebuild_policy" {
  for_each = var.services
  role     = aws_iam_role.codebuild_role[each.key].name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken" # This was missing and is required first
        ],
        Resource = "*" # GetAuthorizationToken must be wildcard
      },
      # ECR permissions
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = aws_ecr_repository.repo[each.key].arn
      },
      # Logging permissions
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "*"
        ]
      },
      # S3 permissions
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
        ]
      },
      # CodeCommit permissions (if using CodeCommit)
      {
        Effect = "Allow",
        Action = [
          "codecommit:GitPull"
        ],
        Resource = [
          "*"
        ]
      },
      # KMS permissions
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        Resource = "*"
      },
      # CodeStar Connections permissions (for GitHub/Bitbucket)
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

// Storage Resources

# Random suffix for S3 bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.name}-artifacts-${random_id.suffix.hex}"
  force_destroy = true
}

# ECR Repositories (one per service)
resource "aws_ecr_repository" "repo" {
  for_each = var.services
  name     = each.key
}

// CI/CD Pipeline Components

resource "aws_codedeploy_app" "app" {
  for_each = var.services
  name     = "${var.name}-${each.key}-codedeploy-app-${terraform.workspace}"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  for_each              = var.services
  app_name              = "${var.name}-${each.key}-codedeploy-app-${terraform.workspace}"
  deployment_group_name = "${var.name}-deployment-group-${terraform.workspace}-${each.key}"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      value = "${var.name}-codedeploy-agent"
      type  = "KEY_AND_VALUE"
    }
  }

}

resource "aws_codebuild_project" "push" {
  for_each     = var.services
  name         = "${each.key}-push-to-ecr-${var.name}-${terraform.workspace}"
  service_role = aws_iam_role.codebuild_role[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "REPO_NAME"
      value = each.key
    }
    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.repo[each.key].repository_url
    }
    environment_variable {
      name  = "SOURCE_IMAGE"
      value = each.value.image
    }

    environment_variable {
      name  = "PORT"
      value = each.value.port
    }

    environment_variable {
      name  = "TARGET_PORT"
      value = each.value.target_port
    }

    dynamic "environment_variable" {
      for_each = each.value.environment
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      
      phases:
        install:
          commands:
            - echo "🛠 Installing jq and awk..."
            - apt install -y jq original-awk

        pre_build:
          commands:
            - echo "📁 Copying source code to working directory..."
            - cp -r . /tmp/source-code

            - echo "🔐 Logging in to ECR..."
            - aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $ECR_URI
            - docker pull $SOURCE_IMAGE

            - echo "📦 Fetching latest tag from ECR..."
            - |
              REPO_NAME=$(echo "$ECR_URI" | cut -d'/' -f2)
              latest_tag=$(aws ecr describe-images \
                --repository-name "$REPO_NAME" \
                --region ap-southeast-1 \
                --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
                --output text)

              echo "Latest tag: $latest_tag" 
            - |
              if [ "$latest_tag" = "None" ] || [ "$latest_tag" = "null" ]; then
                new_tag="1.0.0"
                echo "🆕 Setting new_tag to $new_tag"
              else
                major=$(echo $latest_tag | awk -F. '{print $1}')
                minor=$(echo $latest_tag | awk -F. '{print $2}')
                patch=$(echo $latest_tag | awk -F. '{print $3}')
                patch=$((patch + 1))
                new_tag="$major.$minor.$patch"
                echo "🏷 New tag: $new_tag"
              fi
        build:
          commands:
            - echo "🏗️ Tagging images..."
            - docker tag $SOURCE_IMAGE $ECR_URI:$new_tag

        post_build:
          commands:
            - echo "🚀 Pushing to ECR..."
            - docker push $ECR_URI:$new_tag

            - echo "📝 Generating output artifacts..."
            - echo "ECR_URI=$ECR_URI" > image.env
            - echo "IMAGE_TAG=$new_tag" >> image.env
            - echo "REPO_NAME=$REPO_NAME" >> image.env
            - echo "PORT=$PORT" >> image.env
            - echo "TARGET_PORT=$TARGET_PORT" >> image.env

            %{for key, value in each.value.environment~}
- echo "${key}=${can(parseint(value, 10)) ? value : "\"${value}\""}" >> image.env
            %{endfor}

            - echo "📦 Merging source code back..."
            - cp -r /tmp/source-code/* . || true

      artifacts:
        files:
          - image.env
          - appspec.yml
          - scripts/**
        discard-paths: yes
    EOT
  }
}


resource "aws_codebuild_project" "scan" {
  for_each     = var.services
  name         = "${each.key}-scan-${var.name}-${terraform.workspace}"
  service_role = aws_iam_role.codebuild_role[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "IMAGE"
      value = each.value.image # ví dụ image:tag được Lambda truyền vào hoặc hardcode
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        pre_build:
          commands:
            - curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        build:
          commands:
            - trivy image $IMAGE --format json --output trivy-report.json || true 
      artifacts:
        files: 
          - trivy-report.json
    EOT
  }
}

# CodePipelines (one per service)
resource "aws_codepipeline" "pipeline" {
  for_each = var.services
  name     = "${each.key}-pipeline-${var.name}-${terraform.workspace}"
  role_arn = aws_iam_role.codepipeline_role.arn

  depends_on = [
    aws_codebuild_project.push,
    aws_codebuild_project.scan,
    aws_iam_role_policy.codepipeline_policy
  ]

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  # Stages 1: Source
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = "main"
        DetectChanges    = true
      }
    }
  }

  # Stages 2: Scan with Trivy
  stage {
    name = "Scan-${each.key}-${var.name}-${terraform.workspace}"
    action {
      name            = "TrivyScan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ProjectName = aws_codebuild_project.scan[each.key].name
      }
      output_artifacts = ["scan_output"]
    }
  }

  # Stages 3: Push to ECR 
  stage {
    name = "Push-ToECR-${each.key}-${var.name}-${terraform.workspace}"
    action {
      name             = "PushToECR"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["push_output"]
      configuration = {
        ProjectName = aws_codebuild_project.push[each.key].name
      }
    }
  }

  # Stages 4: Deploy to EC2 
  stage {
    name = "Deploy-${each.key}-${var.name}-EC2-Dev"
    action {
      name            = "CodeDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["push_output"]
      configuration = {
        ApplicationName     = "${var.name}-${each.key}-codedeploy-app-${terraform.workspace}"
        DeploymentGroupName = "${var.name}-deployment-group-${terraform.workspace}-${each.key}"
      }
    }
  }
}
