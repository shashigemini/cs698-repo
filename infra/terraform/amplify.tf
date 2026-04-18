resource "aws_amplify_app" "frontend" {
  name         = "cs698-spiritual-qa"
  repository   = var.repo_clone_url
  access_token = var.github_token

  # Respect the amplify.yml already in the repo root
  enable_branch_auto_build    = false
  enable_branch_auto_deletion = false

  environment_variables = {
    API_BASE_URL          = var.api_base_url
    ANDROID_PACKAGE_NAME  = "com.shashigemini.cs698repo"
    ANDROID_CERT_HASH     = "DUMMY_HASH"
    IOS_BUNDLE_ID         = "com.shashigemini.cs698repo"
    IOS_TEAM_ID           = "DUMMY_TEAM_ID"
    SECURITY_WATCHER_MAIL = "security@spiritualqa.com"
    SSL_CERT_FINGERPRINT  = "DUMMY_FINGERPRINT"
    USE_SSL_PINNING       = "false"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "main"
  framework   = "Flutter"
  stage       = "PRODUCTION"

  environment_variables = {}
}

resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Triggered by deploy-aws-amplify.yml GitHub Action"
}
