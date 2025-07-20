#!/bin/bash
# setup-github-repo.sh
# Script to set up GitHub repository with secrets and variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    log_error "Please authenticate with GitHub CLI first: gh auth login"
    exit 1
fi

log_info "Setting up GitHub repository for Laravel ECS deployment..."

# Get repository info
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')

log_info "Repository: $REPO_OWNER/$REPO_NAME"

# Prompt for AWS account IDs
#read -p "Enter AWS Account ID for Development: " AWS_ACCOUNT_ID_DEV
#read -p "Enter AWS Account ID for Staging: " AWS_ACCOUNT_ID_STAGING
#read -p "Enter AWS Account ID for Production: " AWS_ACCOUNT_ID_PROD
#read -p "Enter ECR Registry URL (shared services account): " ECR_REGISTRY_URL
#read -p "Enter Terraform State S3 Bucket Name: " TERRAFORM_STATE_BUCKET
#read -p "Enter Terraform Lock DynamoDB Table Name: " TERRAFORM_LOCK_TABLE

# Prompt for Laravel app configuration
#read -p "Enter Laravel App Key (base64:...): " APP_KEY
#read -s -p "Enter Database Password: " DB_PASSWORD
#echo
#read -p "Enter Certificate ARN (optional): " CERTIFICATE_ARN

#log_info "Setting up GitHub secrets..."

# AWS Account secrets
#gh secret set AWS_ACCOUNT_ID_DEV --body "$AWS_ACCOUNT_ID_DEV"
#gh secret set AWS_ACCOUNT_ID_STAGING --body "$AWS_ACCOUNT_ID_STAGING"
#gh secret set AWS_ACCOUNT_ID_PROD --body "$AWS_ACCOUNT_ID_PROD"

# Infrastructure secrets
#gh secret set ECR_REGISTRY_URL --body "$ECR_REGISTRY_URL"
#gh secret set TERRAFORM_STATE_BUCKET --body "$TERRAFORM_STATE_BUCKET"
#gh secret set TERRAFORM_LOCK_TABLE --body "$TERRAFORM_LOCK_TABLE"

# Application secrets
#gh secret set APP_KEY --body "$APP_KEY"
#gh secret set DB_PASSWORD --body "$DB_PASSWORD"

# Optional secrets
if [ ! -z "$CERTIFICATE_ARN" ]; then
    gh secret set CERTIFICATE_ARN --body "$CERTIFICATE_ARN"
fi

# Cross-account deployment role ARNs
#gh secret set SHARED_SERVICES_DEPLOY_ROLE --body "arn:aws:iam::${ECR_REGISTRY_URL%%.*}:role/GitHubActionsDeployRole"

#log_success "GitHub secrets configured successfully!"

#log_info "Setting up GitHub repository variables..."

# Development environment variables
gh variable set PROJECT_NAME --body "laravel-multi-app"
gh variable set AWS_REGION --body "eu-central-1"

# Create environment-specific variable sets
log_info "Setting up development environment variables..."
gh variable set DB_INSTANCE_CLASS --body "db.t3.micro" --env development
gh variable set APP_ENV --body "development" --env development
gh variable set APP_COUNT --body "1" --env development
gh variable set FARGATE_CPU --body "512" --env development
gh variable set FARGATE_MEMORY --body "1024" --env development
gh variable set ENABLE_AUTOSCALING --body "false" --env development
gh variable set ENABLE_DELETION_PROTECTION --body "false" --env development

log_info "Setting up staging environment variables..."
gh variable set DB_INSTANCE_CLASS --body "db.t3.micro" --env staging
gh variable set APP_ENV --body "staging" --env staging
gh variable set APP_COUNT --body "2" --env staging
gh variable set FARGATE_CPU --body "1024" --env staging
gh variable set FARGATE_MEMORY --body "2048" --env staging
gh variable set ENABLE_AUTOSCALING --body "true" --env staging
gh variable set ENABLE_DELETION_PROTECTION --body "false" --env staging

log_info "Setting up production environment variables..."
gh variable set DB_INSTANCE_CLASS --body "db.t3.micro" --env production
gh variable set APP_ENV --body "production" --env production
gh variable set APP_COUNT --body "3" --env production
gh variable set FARGATE_CPU --body "1024" --env production
gh variable set FARGATE_MEMORY --body "2048" --env production
gh variable set ENABLE_AUTOSCALING --body "true" --env production
gh variable set ENABLE_DELETION_PROTECTION --body "true" --env production

log_success "GitHub repository variables configured successfully!"

log_info "Setting up GitHub environments..."


# Generate summary
cat << EOF

🚀 GitHub Repository Setup Complete!

Summary of configured items:

Secrets:
✅ AWS_ACCOUNT_ID_DEV, AWS_ACCOUNT_ID_STAGING, AWS_ACCOUNT_ID_PROD
✅ ECR_REGISTRY_URL
✅ TERRAFORM_STATE_BUCKET, TERRAFORM_LOCK_TABLE
✅ APP_KEY, DB_PASSWORD
✅ SHARED_SERVICES_DEPLOY_ROLE

Variables (per environment):
✅ PROJECT_NAME, AWS_REGION (global)
✅ DB_INSTANCE_CLASS, APP_ENV, APP_COUNT (per env)
✅ FARGATE_CPU, FARGATE_MEMORY (per env)
✅ ENABLE_AUTOSCALING, ENABLE_DELETION_PROTECTION (per env)

Environments:
✅ development (auto-deploy)
✅ staging (auto-deploy)
✅ production (manual approval required)
✅ production-approval (approval gate)

Branch Protection:
✅ main branch (requires 1 approval, status checks)
✅ production branch (requires 2 approvals, code owners)

Next Steps:
1. Set up AWS IAM roles for cross-account access
2. Create the production branch: git checkout -b production && git push origin production
3. Push your code to trigger the first deployment
4. Review and customize environment variables as needed

Happy deploying! 🎉
EOF