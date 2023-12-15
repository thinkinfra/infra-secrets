# infra-secrets

Repository for managing vault secrets.

## Shift-Left with SAML, AWS IAM, and AGE Keys

This guide provides steps for setting up pre-commit hooks, managing secrets, and integrating SAML-based authentication with AWS IAM for KMS access.

## Table of Contents

1. [TLDR - Video & Presentation](#video-and-presentation)
2. [Pre-commit and Pre-requisites](#pre-commit-and-sops-pre-requisites)
4. [Managing Secrets](#managing-secrets)
5. [SAML Authentication with AWS IAM](#saml-authentication-with-aws-iam-using-okta)
6. [Workflows](#workflows-configuration)
7. [Setup and Contributions](#setup-and-contributions)
8. [Disclaimer](#disclaimer)

## Video and Presentation

- [Demo](https://earnest.zoom.us/rec/share/5pza2S4CwfMvyaNTB0gmF1qN8zHOhj4kiAe8o9Z8z1i72gK_5NZdQcKRqohcW-XW.iSTjK6i-1BpQNUjz)
-> **Passcode:** 2ff4e&E4

- [Presentation](https://docs.google.com/presentation/d/1Yrqq4AgMq5SdXSyCOiXWXcHVzgMxF7BNETbUCFgFfY8/edit?usp=sharing)

- [How to: Use (Self-Service) Secret Management Workflow](https://meetearnest.atlassian.net/wiki/x/y4DEuw)

## Pre-commit and Sops Pre-requisites
```bash
git clone https://github.com/meetearnest/infra-secrets.git
cd infra-secrets
```

### Sops
SOPS is an editor of encrypted files that supports YAML, JSON, ENV, INI and BINARY formats and encrypts with AWS KMS, GCP KMS, Azure Key Vault, age, and PGP.
```bash
#sops using brew
brew install sops

#or using asdf
brew unlink sops
asdf plugin-add sops https://github.com/feniix/asdf-sops.git
asdf install sops 3.8.0
```

### Pre-commit
The pre-commit hook is run first, before you even type in a commit message. It's used to inspect the snapshot that's about to be committed, to see if you've forgotten something, to make sure tests run, or to examine whatever you need to inspect in the code.

```bash
#pre-commit using pip
pip install pre-commit
pre-commit install

#or using brew
brew install pre-commit && pre-commit install
```



## SAML Authentication with AWS IAM using OKTA

Details on integrating Okta as a SAML Identity Provider (IdP) with AWS IAM for secure, federated access to AWS resources, including KMS.


[How to Setup SAML](https://meetearnest.atlassian.net/wiki/spaces/EN/pages/2717089856/Migrate+from+aws-sts-token-generator+to+saml2aws)

Using SAML (Security Assertion Markup Language) typically involves the following:

- Identity Provider (IdP) Setup: Configure a SAML IdP like Okta or OneLogin. This includes setting up user accounts and groups.
- Service Provider (SP) Configuration: Configure the application or service (like AWS, Google Apps, etc.) to use SAML for authentication. This often involves uploading IdP metadata to the SP and configuring SAML settings.
- User Authentication: Users authenticate themselves with the IdP using their credentials.
- SAML Assertion: After successful authentication, the IdP sends a SAML assertion (a XML document) to the SP. This assertion contains the user's identity and possibly groups or roles.
- Access Control: The SP uses the SAML assertion to grant access to the user. The level of access is usually determined by the user's role or group memberships specified in the assertion.
- Single Sign-On (SSO): SAML enables SSO, allowing users to access multiple services with a single authentication at the IdP.

For instance, to configure your application, use the following command:
```bash
# This is an example, replace 'your-config' with your actual configuration details
source ~/.secrets/saml2aws.sh sandbox

account {
  DisableSessions: false
  DisableRememberDevice: false
  URL: https://meetearnest.okta.com/home/amazon_aws/0oap56m1ntr0XKqug0x7/272
  Username: 
  Provider: Okta
  MFA: TOTP
  SkipVerify: false
  AmazonWebservicesURN: urn:amazon:webservices
  SessionDuration: 3600
  Profile: saml
  RoleARN: 
  Region: us-east-1
}

Configuration saved for IDP account: est-sandbox
Using IdP Account est-sandbox to access Okta https://meetearnest.okta.com/home/amazon_aws/0oap56m1ntr0XKqug0x7/272
Authenticating as jeffry.milan@earnest.com ...
Selected role: arn:aws:iam::644712362974:role/Okta-Sandbox-Administrator
Requesting AWS credentials using SAML assertion.
Logged in as: arn:aws:sts::644712362974:assumed-role/Okta-Sandbox-Administrator/jeffry.milan@earnest.com

Your new access key pair has been stored in the AWS configuration.
Note that it will expire at 2023-12-11 12:39:38 -0800 PST
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile Okta-Sandbox-Administrator ec2 describe-instances).
```


## Managing Secrets

Create a New Secret
```bash
cd secrets/<ENV>/infra
echo "api_key: '123456789'" > new-secret.yaml
sops --encrypt --in-place new-secret.yaml
```

Modify an Existing Secret
```bash
sops --decrypt --in-place existing-secret.yaml
vim existing-secret.yaml
sops --encrypt --in-place existing-secret.yaml
```


## Workflows Configuration

- **Secret Management Workflow** (`secret-management-workflow.yaml`): Automates creation and updating of secrets.

```yaml
# Contents of .github/workflows/secret-management-workflow.yaml
name: (Self-Service) Secret Management Workflow

on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform (create or update)'
        required: true
        type: choice
        options:
          - create
          - update
      environment:
        description: 'Select Environment'
        required: true
        type: choice
        options:
          - production
          - staging
          - sandbox
      secret_category:
        description: 'Select Secret Category'
        required: true
        type: choice
        options:
          - customer-experience
          - infra
          - lending
      service:
        description: 'Name of the service (secret file name without extension)'
        required: true
      secret_type:
        description: 'Type of the secret (cert or singleline)'
        required: true
        default: 'singleline'
      secret_key:
        description: 'Secret key to add or update'
        required: true
      secret_value:
        description: 'Secret value for the key'
        required: true
      jira_ticket_id:
        description: 'JIRA Ticket ID'
        required: true
      secret_manager:
        description: 'Vault or AWS Secret Manager(TODO) '
        required: true
        type: choice
        default: vault
        options:
          - vault
          - secretmanager
# DISABLED: INPUT PARAMETERS
      # sops_version:
      #   description: 'SOPS configuration version (v1 or v2)'
      #   required: true
      #   type: choice
      #   options:
      #     - v1
      #     - v2
      # logLevel:
      #   description: 'Log level'
      #   required: true
      #   default: 'warning'
      #   type: choice
      #   options:
      #     - info
      #     - warning
      #     - debug

jobs:
  check-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Check branch
        if: github.ref != 'refs/heads/main'
        run: |
          echo "This workflow is only allowed to run on the main branch."
          exit 1
  process-secret-file:
    needs: [check-branch]
    name: Progressing -> JIRA ${{ github.event.inputs.jira_ticket_id }}
    runs-on: self-hosted-${{ github.event.inputs.environment }}
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'

      - name: Install dependency tools
        run: |
          sudo apt-get update
          sudo apt-get install -y wget git gh
          python -m pip install --upgrade pip

      # Export AGE Key
      - name: Set COMMON_AGE_KEY
        run: |
          AGE_KEY_FILE="sops-age-key.txt"
          echo "${{ secrets.COMMON_AGE_KEY }}" > "$AGE_KEY_FILE"
          echo "SOPS_AGE_KEY_FILE=$AGE_KEY_FILE" >> $GITHUB_ENV

      - name: Configure Git for GPG
        run: |
          git config --global user.signingkey 9B0444DF26E34586
          git config --global commit.gpgsign true

      # Import Generic PGP Keys (Private and Public)
      - name: Import Generic & svc-git-infra-read PGP Keys
        run: |
          echo "Importing Generic PGP private key..."
          echo "${{ secrets.CI_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing Generic PGP public key..."
          echo "${{ secrets.CI_PGP_PUBLIC_KEY }}" | gpg --import 2>&1
          echo "Importing svc-git-infra-read PGP private key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing svc-git-infra-read PGP public key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PUBLIC_KEY }}" | gpg --import 2>&1

      # Import Generic PGP Keys (Private and Public)
      - name: Import PGP Keys and Capture Fingerprint for ${{ github.event.inputs.environment }} environment
        run: |
          import_and_extract_fingerprint() {
            PRIVATE_KEY="$1"
            PUBLIC_KEY="$2"
            echo "Importing PGP private key..."
            echo "$PRIVATE_KEY" | gpg --batch --no-tty --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP private key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Importing PGP public key..."
            echo "$PUBLIC_KEY" | gpg --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP public key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Listing imported keys..."
            gpg --list-keys
            gpg --list-secret-keys

            echo "Extracting fingerprint..."
            FINGERPRINT=$(gpg --list-secret-keys --with-colons | grep '^fpr' | head -n 1 | cut -d':' -f10)

            if [ -z "$FINGERPRINT" ]; then
              echo "Failed to extract fingerprint"
              exit 1
            fi

            echo "Fingerprint extracted: $FINGERPRINT"
            echo "FINGERPRINT=$FINGERPRINT" >> $GITHUB_ENV
          }

          # Use the environment variables
          case "${{ github.event.inputs.environment }}" in
            "sandbox")
              import_and_extract_fingerprint "${{ secrets.SANDBOX_PGP_PRIVATE_KEY }}" "${{ secrets.SANDBOX_PGP_PUBLIC_KEY }}"
              ;;
            "staging")
              import_and_extract_fingerprint "${{ secrets.STAGING_PGP_PRIVATE_KEY }}" "${{ secrets.STAGING_PGP_PUBLIC_KEY }}"
              ;;
            "production")
              import_and_extract_fingerprint "${{ secrets.PRODUCTION_PGP_PRIVATE_KEY }}" "${{ secrets.PRODUCTION_PGP_PUBLIC_KEY }}"
              ;;
            *)
              echo "::error ::Invalid secret category."
              exit 1
              ;;
          esac

      - name: Install sops
        run: |
          wget https://github.com/mozilla/sops/releases/download/v3.8.0/sops_3.8.0_amd64.deb
          sudo dpkg -i sops_3.8.0_amd64.deb

      - name: Handle Secret Value
        run: |
          INP_SECRET_VALUE=$(jq -r '.inputs.secret_value' $GITHUB_EVENT_PATH)
          echo "::add-mask::$INP_SECRET_VALUE"
          echo SECRET_VALUE="$INP_SECRET_VALUE" >> $GITHUB_ENV

      - name: Define Secret File Path
        run: |
          echo "SECRET_FILE_PATH=secrets/${{ github.event.inputs.environment }}/${{ github.event.inputs.secret_category }}/${{ github.event.inputs.service }}.yaml" >> $GITHUB_ENV

      - name: Check if Secret File Exists or Create New
        run: |
          if [ "${{ github.event.inputs.action }}" == "create" ]; then
            if [ -f "${{ env.SECRET_FILE_PATH }}" ]; then
              echo "::error::Secret file already exists for the service. Cannot create a new one."
              exit 1
            fi
            echo "::notice::Creating new secret file for the new service."
            mkdir -p "$(dirname ${{ env.SECRET_FILE_PATH }})"
            echo "${{ github.event.inputs.secret_key }}: " > "${{ env.SECRET_FILE_PATH }}"
            echo "isNewFile=true" >> $GITHUB_ENV
          elif [ "${{ github.event.inputs.action }}" == "update" ]; then
            if [ ! -f "${{ env.SECRET_FILE_PATH }}" ]; then
              echo "::error::Secret file does not exist. Cannot update non-existent file."
              exit 1
            fi
            echo "::notice::Updating secret for the existing service."
            echo "isNewFile=false" >> $GITHUB_ENV
          else
            echo "::error::Invalid action specified."
            exit 1
          fi

      - name: Define Temporary Decrypted File Path
        run: |
          DECRYPTED_FILE_PATH="$(dirname ${{ env.SECRET_FILE_PATH }})/temp_decrypted_file.yaml"
          echo "DECRYPTED_FILE_PATH=$DECRYPTED_FILE_PATH" >> $GITHUB_ENV

      - name: Decrypt Secret File or Skip If New
        if: env.isNewFile == 'false'
        run: |
          echo "::notice::Decrypting existing secret file."
          sops --config configs/v1_sops.yaml --decrypt "${{ env.SECRET_FILE_PATH }}" > "${{ env.DECRYPTED_FILE_PATH }}"

      - name: Update Secret File Based on Secret Type
        run: |
          KEY="${{ github.event.inputs.secret_key }}"
          SECRET_TYPE="${{ github.event.inputs.secret_type }}"
          ACTION="${{ github.event.inputs.action }}"
          DECRYPTED_FILE_PATH="${{ env.DECRYPTED_FILE_PATH }}"
          SECRET_VALUE="${{ env.SECRET_VALUE }}"

          # Function to add or update the secret
          add_or_update_secret() {
            if [ "$SECRET_TYPE" == "cert" ]; then
              # Multi-line string (certificate) handling
              echo "$KEY: |" >> "$DECRYPTED_FILE_PATH"
              echo "$SECRET_VALUE" | base64 --decode | sed 's/^/    /' >> "$DECRYPTED_FILE_PATH"
            else
              # Single-line secret handling
              echo "$KEY: $SECRET_VALUE" >> "$DECRYPTED_FILE_PATH"
            fi
          }

          # Check if the key already exists in the file
          if grep -q "^$KEY:" "$DECRYPTED_FILE_PATH"; then
            if [ "$ACTION" == "update" ]; then
              echo "::warning::Key $KEY exists and will be overwritten."
              echo "KEY_OVERWRITTEN=true" >> $GITHUB_ENV
              sed -i "/^$KEY:/d" "$DECRYPTED_FILE_PATH" # Remove the existing key
              add_or_update_secret # Add the updated key
            else
              echo "Key $KEY already exists and action is not update. Skipping."
            fi
          else
            echo "Key $KEY does not exist. Adding it to the file."
            add_or_update_secret # Add the new key
          fi

      - name: Re-Encrypt Secret File
        run: |
          sops --config configs/v1_sops.yaml --encrypt "${{ env.DECRYPTED_FILE_PATH }}" > "${{ env.SECRET_FILE_PATH }}"

      - name: Delete Existing Branch
        run: |
          BRANCH="secret/${{ github.event.inputs.service }}/${{ github.event.inputs.jira_ticket_id }}"
          EXISTS=$(git ls-remote --heads origin $BRANCH)
          if [ -z "$EXISTS" ]; then
            echo "Branch $BRANCH does not exist on remote. Skipping deletion."
          else
            echo "Deleting existing remote branch $BRANCH."
            git push origin --delete $BRANCH
          fi

      - name: Commit and Push Changes
        run: |
          git config --global user.name 'svc-git-infra-read'
          git config --global user.email 'earnest-infra-services@earnest.com'
          BRANCH="secret/${{ github.event.inputs.service }}/${{ github.event.inputs.jira_ticket_id }}"
          git checkout -b "$BRANCH"
          git add "${{ env.SECRET_FILE_PATH }}"
          if [ "${{ github.event.inputs.action }}" == "create" ]; then
            COMMIT_MESSAGE="Create new secret for new service: ${{ github.event.inputs.service }} related to JIRA ${{ github.event.inputs.jira_ticket_id }}"
          else
            COMMIT_MESSAGE="Update secret for existing service: ${{ github.event.inputs.service }} related to JIRA ${{ github.event.inputs.jira_ticket_id }}"
          fi
          git commit -m "$COMMIT_MESSAGE"
          git push --set-upstream origin "$BRANCH"

      - name: Create Pull Request
        run: |
          SERVICE="${{ github.event.inputs.service }}"
          JIRA_TICKET_ID="${{ github.event.inputs.jira_ticket_id }}"
          ACTION="${{ github.event.inputs.action }}"
          BRANCH="secret/$SERVICE/$JIRA_TICKET_ID"
          KEY="${{ github.event.inputs.secret_key }}"
          KEY_OVERWRITTEN=${{ env.KEY_OVERWRITTEN }}

          # PR Title
          if [ "$ACTION" == "create" ]; then
            PR_TITLE="New Secret Creation: $SERVICE for JIRA $JIRA_TICKET_ID"
          else
            PR_TITLE="Secret Update: $SERVICE for JIRA $JIRA_TICKET_ID"
          fi

          # Start constructing PR Body
          echo "## Changes" > pr_body.md


          # Add a warning or a note based on whether the key was overwritten
          if [ "$KEY_OVERWRITTEN" == "true" ]; then
            echo "- Updating the secret for the existing service: $SERVICE related to JIRA Ticket: [$JIRA_TICKET_ID](https://meetearnest.atlassian.net/browse/$JIRA_TICKET_ID)" >> pr_body.md
            echo "### ⚠️ IMPORTANT: Secret Key Overwritten" >> pr_body.md
            echo "This Pull Request includes changes that overwrite an existing secret key: **_('$KEY')_**. Please review the following points carefully and ensure all necessary actions are taken:" >> pr_body.md
            echo "- [ ] **Impact Assessment**: Ensure that the updated key value does not adversely affect any systems or environments where this key is used." >> pr_body.md
            echo "- [ ] **Confirmation of Necessity**: Confirm that the overwrite is necessary and intentional. Unintended overwrites can lead to system outages or security vulnerabilities." >> pr_body.md
            echo "- [ ] **Verification of Value**: Double-check the new secret value for accuracy. Incorrect secret values can cause unexpected issues in dependent services." >> pr_body.md
            echo "- [ ] **Stakeholder Notification**: Notify all relevant stakeholders about this change, especially if the secret is shared across multiple teams or services." >> pr_body.md
            echo "- [ ] **Audit and Testing**: After merging, monitor the affected systems closely and conduct thorough testing to ensure they continue to operate as expected." >> pr_body.md
            echo "" >> pr_body.md
          else
            echo "- Creating a new secret for the service: $SERVICE related to JIRA Ticket: [$JIRA_TICKET_ID](https://meetearnest.atlassian.net/browse/$JIRA_TICKET_ID)" >> pr_body.md
            echo "### 📓 NOTE: New Secret Creation" >> pr_body.md
            echo "This Pull Request is for creating a new secret key: **_('$KEY')_** for the service. Please ensure that the secret key and value are correctly set and relevant to the service requirements." >> pr_body.md
            echo "" >> pr_body.md
          fi

          # Add References Section
          echo "" >> pr_body.md
          echo "### References" >> pr_body.md
          echo "JIRA Ticket: [$JIRA_TICKET_ID](https://meetearnest.atlassian.net/browse/$JIRA_TICKET_ID)" >> pr_body.md

          # Create the PR using GitHub CLI
          PR_BODY=$(cat pr_body.md)
          rm pr_body.md
          gh pr create --title "$PR_TITLE" \
                        --body "$PR_BODY" \
                        --base main \
                        --head "$BRANCH" \
                        --label "self-service-automation"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Cleanup
        run: |
          rm -f "${{ env.DECRYPTED_FILE_PATH }}"
          gpg --delete-secret-keys --batch --yes ${{ env.FINGERPRINT }}
          rm -f "$SECRET_TEMP_FILE"
          rm -f age_key.txt

        # Additional steps to commit changes, if necessary]
```
- **Secret Publishing Workflow** (`secret-publishing-workflow.yaml`): Handles publication of secrets.

```yaml
# Contents of .github/workflows/secret-publishing-workflow.yaml
name: (Pull Request) Secret Publishing Workflow

on:
  pull_request:
    branches: [ "main","develop","feature/*", "secret/*", "gh-action/*"]
    paths:
      - "secrets/**"
  push:
    branches: [ "main","develop","feature/*", "secret/*", "gh-action/*"]
  workflow_dispatch:

jobs:
  # setting up prerequisites, performing initial checks, or preparing the environment
  pre_job:
    if: github.actor != 'svc-git-infra-read'
    name: Checking duplicate GH Action
    runs-on: self-hosted
    outputs:
      should_skip: ${{ steps.skip_check.outputs.should_skip }}
    steps:
      - id: skip_check
        uses: fkirc/skip-duplicate-actions@v5.3.1
        with:
          skip_after_successful_duplicate: 'true'
  # detecting and preventing the leakage of sensitive information
  gitleaks:
    if: github.actor != 'svc-git-infra-read'
    needs: [pre_job]
    name: Scanning secrets via Gitleaks
    runs-on: ubuntu-latest #self-hosted -> https://github.com/gitleaks/gitleaks-action/issues/125
    environment:
      name: system
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4.0.0
        with:
          node-version: 18
          check-latest: true
      - run: wget -O .gitleaks.toml https://raw.githubusercontent.com/zricethezav/gitleaks/master/config/gitleaks.toml
      - uses: gitleaks/gitleaks-action@v2.3.2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE_KEY}} # Only required for Organizations, not personal accounts.
          GITLEAKS_ENABLE_SUMMARY: true
          GITLEAKS_VERSION: latest
      - name: Save success status
        if: ${{ success() }}
        run: echo "success" > status.txt
      - name: Upload status
        uses: actions/upload-artifact@v3
        with:
          name: status
          path: status.txt
  # automates code review feedback from various linters and analyzers in your CI/CD pipeline
  reviewdog:
    if: github.actor != 'svc-git-infra-read'
    needs: [pre_job]
    name: Review Gitleaks
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - uses: reviewdog/action-gitleaks@v1.4.0
        with:
          github_token: ${{ secrets.github_token }}
          # Change reviewdog reporter if you need [github-pr-check,github-check,github-pr-review].
          reporter: github-pr-review
          # Change reporter level if you need.
          # GitHub Status Check won't become failure with warning.
          level: warning
  # secrets injection for vault secret engine v1
  v1_secret_vault:
    # This job runs only on the push event (i.e., after a merge)
    if: github.event_name == 'push'
    needs: [pre_job,reviewdog,gitleaks]
    name: "v1 Secret Injection via Sops"
    strategy:
      matrix:
        environment: [sandbox, staging, production]
      fail-fast: false
    runs-on: self-hosted-${{ matrix.environment }}
    environment: ${{ matrix.environment }} #no longer required

    steps:
      - name: Clean up working directory
        run: rm -rf ./*

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download status
        uses: actions/download-artifact@v3
        with:
          name: status

      - name: Check Gitleaks status
        run: |
          if [[ "$(cat status.txt)" != "success" ]]; then
            echo "Gitleaks check failed. Exiting."
            exit 1s
          fi

      - name: Install GPG
        run: |
          gpg --version
          sudo apt-get update
          sudo apt-get install -y gnupg

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'

      - name: Install dependency tools
        run: |
          sudo apt-get update
          sudo apt-get install -y wget git ssh
          python -m pip install --upgrade pip

      # Import Generic PGP Keys (Private and Public)
      - name: Import Generic & svc-git-infra-read PGP Keys
        run: |
          echo "Importing Generic PGP private key..."
          echo "${{ secrets.CI_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing Generic PGP public key..."
          echo "${{ secrets.CI_PGP_PUBLIC_KEY }}" | gpg --import 2>&1
          echo "Importing svc-git-infra-read PGP private key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing svc-git-infra-read PGP public key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PUBLIC_KEY }}" | gpg --import 2>&1

      # Import Generic PGP Keys (Private and Public)
      - name: Import PGP Keys and Capture Fingerprint for ${{ matrix.environment }} environment
        run: |
          import_and_extract_fingerprint() {
            PRIVATE_KEY="$1"
            PUBLIC_KEY="$2"
            echo "Importing PGP private key..."
            echo "$PRIVATE_KEY" | gpg --batch --no-tty --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP private key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Importing PGP public key..."
            echo "$PUBLIC_KEY" | gpg --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP public key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Listing imported keys..."
            gpg --list-keys
            gpg --list-secret-keys

            echo "Extracting fingerprint..."
            FINGERPRINT=$(gpg --list-secret-keys --with-colons | grep '^fpr' | head -n 1 | cut -d':' -f10)

            if [ -z "$FINGERPRINT" ]; then
              echo "Failed to extract fingerprint"
              exit 1
            fi

            echo "Fingerprint extracted: $FINGERPRINT"
            echo "FINGERPRINT=$FINGERPRINT" >> $GITHUB_ENV
          }

          # Use the environment variables
          case "${{ matrix.environment }}" in
            "sandbox")
              import_and_extract_fingerprint "${{ secrets.SANDBOX_PGP_PRIVATE_KEY }}" "${{ secrets.SANDBOX_PGP_PUBLIC_KEY }}"
              ;;
            "staging")
              import_and_extract_fingerprint "${{ secrets.STAGING_PGP_PRIVATE_KEY }}" "${{ secrets.STAGING_PGP_PUBLIC_KEY }}"
              ;;
            "production")
              import_and_extract_fingerprint "${{ secrets.PRODUCTION_PGP_PRIVATE_KEY }}" "${{ secrets.PRODUCTION_PGP_PUBLIC_KEY }}"
              ;;
            *)
              echo "::error ::Invalid secret category."
              exit 1
              ;;
          esac

      # Export AGE Key
      - name: Set COMMON_AGE_KEY
        run: |
          AGE_KEY_FILE="sops-age-key.txt"
          echo "${{ secrets.COMMON_AGE_KEY }}" > "$AGE_KEY_FILE"
          echo "SOPS_AGE_KEY_FILE=$AGE_KEY_FILE" >> $GITHUB_ENV

      - name: Configure Git for GPG
        run: |
          git config --global user.signingkey 9B0444DF26E34586
          git config --global commit.gpgsign true

      - name: Copy v1_sops.yaml
        run: cp -f configs/v1_sops.yaml .sops.yaml

      - name: Set up SSH Agent
        uses: webfactory/ssh-agent@v0.8.0
        with:
          ssh-private-key: ${{ secrets.SVC_GIT_INFRA_READ_SSH_PRIVATE_KEY }}

      - name: Add GitHub.com to known hosts
        run: ssh-keyscan github.com >> ~/.ssh/known_hosts

      - name: Install sops
        run: |
          wget https://github.com/mozilla/sops/releases/download/v3.8.0/sops_3.8.0_amd64.deb
          sudo dpkg -i sops_3.8.0_amd64.deb

      - name: Verify sops installation
        run: sops --version

      # - name: Get All Changed Files
      #   id: files
      #   with:
      #     format: 'yaml'
      #   uses: jitterbit/get-changed-files@v1

      - name: Get changed files in the secrets folder
        id: files
        uses: tj-actions/changed-files@v40
        with:
          files: secrets/**/*.{yaml,yml}  # Targeting specific files in the secrets directory
          files_ignore: secrets/CODEOWNERS  # Ignoring the CODEOWNERS file in the secrets directory

      - name: Check for Relevant Changes
        id: check_changes
        run: |
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          relevant_changes="false"
          for file in "${modified_files[@]}"; do
            # Extract the folder name from the file path
            path_components=(${file//\// })
            folder_name=${path_components[2]}  # Adjust based on your directory structure

            if [[ $file == secrets/${{ matrix.environment }}/$folder_name/* ]]; then
              relevant_changes="true"
              break
            fi
          done
          echo "RELEVANT_CHANGES=$relevant_changes" >> $GITHUB_ENV

      # Set environment variables based on the matrix environment
      - if: env.RELEVANT_CHANGES == 'true'
        name: Set environment variables for ${{ matrix.environment }} environment
        run: |
          case ${{ matrix.environment }} in
            sandbox)
              VAULT_ADDR="${{ secrets.SANDBOX_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.SANDBOX_VAULT_TOKEN }}"
              ;;
            staging)
              VAULT_ADDR="${{ secrets.STAGING_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.STAGING_VAULT_TOKEN }}"
              ;;
            production)
              VAULT_ADDR="${{ secrets.PRODUCTION_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.PRODUCTION_VAULT_TOKEN }}"
              ;;
            *)
              echo "Unsupported environment: ${{ matrix.environment }}"
              exit 1
              ;;
          esac
          echo "VAULT_ADDR=$VAULT_ADDR" >> $GITHUB_ENV
          echo "VAULT_TOKEN=$VAULT_TOKEN" >> $GITHUB_ENV

      - if: env.RELEVANT_CHANGES == 'true'
        name: Decrypt Double-Dotted Secret Files
        run: |
          set -e
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          for file in "${modified_files[@]}"; do
            if [[ $(basename "$file") =~ \..+\.yaml$ ]]; then
              # Extract the folder name from the file path
              path_components=(${file//\// })
              folder_name=${path_components[2]}  # Adjust based on your directory structure

              decrypted_directory="secrets/${{ matrix.environment }}/$folder_name/decrypted"
              mkdir -p "$decrypted_directory"
              decrypted_file_path="$decrypted_directory/$(basename $file)"
              flag_file_path="$decrypted_directory/$(basename $file).decrypted"

              echo "Decrypting double-dot file: $file"
              if sops --config configs/v1_sops.yaml --decrypt $file > $decrypted_file_path; then
                # Create a flag file to indicate successful decryption
                touch "$flag_file_path"
              fi
            fi
          done
      # This is a one time only run to perform sops updatekeys using config: configs/v1_sops.yaml
      - if: env.RELEVANT_CHANGES == 'true'
        name: Process and Update Keys in Secret Files
        run: |
          set -e
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          FILES_TO_COMMIT=()

          for file in "${modified_files[@]}"; do
            # Extract the folder name from the file path
            path_components=(${file//\// })
            folder_name=${path_components[2]}  # Adjust based on your directory structure

            if [[ $file == secrets/${{ matrix.environment }}/$folder_name/* ]]; then
              # Update the keys in the file
              yes | sops --config configs/v2_sops.yaml updatekeys "$file"

              # Add the file to the list to be committed
              FILES_TO_COMMIT+=("$file")
            fi
          done

          if [ ${#FILES_TO_COMMIT[@]} -gt 0 ]; then
            git config --global user.name 'svc-git-infra-read'
            git config --global user.email 'earnest-infra-services@earnest.com'

            # Stage the files for commit
            git add "${FILES_TO_COMMIT[@]}"

            # Check if there are changes to be committed
            if git diff --staged --quiet; then
              echo "No changes in the files to commit."
            else
              git commit -m "Updated keys in modified secret files"

              # Pull the latest changes from the remote branch
              git pull origin main

              # Use SSH for pushing
              git push git@github.com:meetearnest/infra-secrets.git HEAD:main
            fi
          else
            echo "No files to commit."
          fi

      - if: env.RELEVANT_CHANGES == 'true'
        name: Process Secret Files
        run: |
          set -e
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          for file in "${modified_files[@]}"; do
            if [[ $file == secrets/${{ matrix.environment }}/* ]]; then
              # Extract the folder name from the file path
              path_components=(${file//\// })
              folder_name=${path_components[2]}  # Adjust based on your directory structure

              decrypted_directory="secrets/${{ matrix.environment }}/$folder_name/decrypted"  # Update as needed
              decrypted_file_path="$decrypted_directory/$(basename $file)"
              flag_file_path="$decrypted_directory/$(basename $file).decrypted"

              if [[ -f "$flag_file_path" ]]; then
                # Process decrypted file
                echo "Processing decrypted file: $decrypted_file_path"

                # Convert YAML to JSON using yq
                pip install yq
                yq -r . "$decrypted_file_path" > "${decrypted_file_path%.yaml}.json"

                # Debug output the contents of the JSON file for debugging
                # echo "Converted JSON content:"
                # cat "${decrypted_file_path%.yaml}.json"

                # Construct the Vault path
                filename_without_extension="$(basename $decrypted_file_path .yaml)"
                IFS='.' read -r secret_name sub_path <<< "$filename_without_extension"
                vault_path="secret/$secret_name/$sub_path"
                echo "Uploading to Vault at path: $vault_path"

                # Upload to Vault
                curl -H "X-Vault-Token: $VAULT_TOKEN" \
                      -H "Content-Type: application/json" \
                      --request POST \
                      --data @"${decrypted_file_path%.yaml}.json" \
                      $VAULT_ADDR/v1/$vault_path
              else
                # File not decrypted, use sops publish
                echo "Publishing secret using sops for file: $file"
                sops publish -y $file
              fi
            fi
          done
  # secrets injection for vault secret engine v2
  v2_secret_vault:
    # This job runs only on the push event (i.e., after a merge)
    if: github.event_name == 'push'
    needs: [pre_job,reviewdog,gitleaks]
    name: "v2 Secret Injection via Sops"
    strategy:
      matrix:
        environment: [sandbox, staging, production]
      fail-fast: false
    runs-on: self-hosted-${{ matrix.environment }}
    environment: ${{ matrix.environment }} #no longer required

    steps:
      - name: Clean up working directory
        run: rm -rf ./*

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download status
        uses: actions/download-artifact@v3
        with:
          name: status

      - name: Check Gitleaks status
        run: |
          if [[ "$(cat status.txt)" != "success" ]]; then
            echo "Gitleaks check failed. Exiting."
            exit 1s
          fi

      - name: Install GPG
        run: |
          gpg --version
          sudo apt-get update
          sudo apt-get install -y gnupg

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'

      - name: Install dependency tools
        run: |
          sudo apt-get update
          sudo apt-get install -y wget git ssh
          python -m pip install --upgrade pip

      # Import Generic PGP Keys (Private and Public)
      - name: Import Generic & svc-git-infra-read PGP Keys
        run: |
          echo "Importing Generic PGP private key..."
          echo "${{ secrets.CI_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing Generic PGP public key..."
          echo "${{ secrets.CI_PGP_PUBLIC_KEY }}" | gpg --import 2>&1
          echo "Importing svc-git-infra-read PGP private key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PRIVATE_KEY }}" | gpg --batch --no-tty --import 2>&1
          echo "Importing svc-git-infra-read PGP public key..."
          echo "${{ secrets.SVC_GIT_INFRA_READ_PGP_PUBLIC_KEY }}" | gpg --import 2>&1

      # Import Generic PGP Keys (Private and Public)
      - name: Import PGP Keys and Capture Fingerprint for ${{ matrix.environment }} environment
        run: |
          import_and_extract_fingerprint() {
            PRIVATE_KEY="$1"
            PUBLIC_KEY="$2"
            echo "Importing PGP private key..."
            echo "$PRIVATE_KEY" | gpg --batch --no-tty --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP private key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Importing PGP public key..."
            echo "$PUBLIC_KEY" | gpg --import 2>&1
            gpg_error=$?

            if [ $gpg_error -ne 0 ]; then
              echo "Failed to import PGP public key, error code: $gpg_error"
              exit $gpg_error
            fi

            echo "Listing imported keys..."
            gpg --list-keys
            gpg --list-secret-keys

            echo "Extracting fingerprint..."
            FINGERPRINT=$(gpg --list-secret-keys --with-colons | grep '^fpr' | head -n 1 | cut -d':' -f10)

            if [ -z "$FINGERPRINT" ]; then
              echo "Failed to extract fingerprint"
              exit 1
            fi

            echo "Fingerprint extracted: $FINGERPRINT"
            echo "FINGERPRINT=$FINGERPRINT" >> $GITHUB_ENV
          }

          # Use the environment variables
          case "${{ matrix.environment }}" in
            "sandbox")
              import_and_extract_fingerprint "${{ secrets.SANDBOX_PGP_PRIVATE_KEY }}" "${{ secrets.SANDBOX_PGP_PUBLIC_KEY }}"
              ;;
            "staging")
              import_and_extract_fingerprint "${{ secrets.STAGING_PGP_PRIVATE_KEY }}" "${{ secrets.STAGING_PGP_PUBLIC_KEY }}"
              ;;
            "production")
              import_and_extract_fingerprint "${{ secrets.PRODUCTION_PGP_PRIVATE_KEY }}" "${{ secrets.PRODUCTION_PGP_PUBLIC_KEY }}"
              ;;
            *)
              echo "::error ::Invalid secret category."
              exit 1
              ;;
          esac

      # Export AGE Key
      - name: Set COMMON_AGE_KEY
        run: |
          AGE_KEY_FILE="sops-age-key.txt"
          echo "${{ secrets.COMMON_AGE_KEY }}" > "$AGE_KEY_FILE"
          echo "SOPS_AGE_KEY_FILE=$AGE_KEY_FILE" >> $GITHUB_ENV

      - name: Configure Git for GPG
        run: |
          git config --global user.signingkey 9B0444DF26E34586
          git config --global commit.gpgsign true

      - name: Copy v2_sops.yaml
        run: cp -f configs/v2_sops.yaml .sops.yaml

      - name: Set up SSH Agent
        uses: webfactory/ssh-agent@v0.8.0
        with:
          ssh-private-key: ${{ secrets.SVC_GIT_INFRA_READ_SSH_PRIVATE_KEY }}

      - name: Add GitHub.com to known hosts
        run: ssh-keyscan github.com >> ~/.ssh/known_hosts

      - name: Install sops
        run: |
          wget https://github.com/mozilla/sops/releases/download/v3.8.0/sops_3.8.0_amd64.deb
          sudo dpkg -i sops_3.8.0_amd64.deb

      - name: Verify sops installation
        run: sops --version

      # - name: Get All Changed Files
      #   id: files
      #   with:
      #     format: 'yaml'
      #   uses: jitterbit/get-changed-files@v1

      - name: Get changed files in the secrets folder
        id: files
        uses: tj-actions/changed-files@v40
        with:
          files: secrets/**/*.{yaml,yml}  # Targeting specific files in the secrets directory
          files_ignore: secrets/CODEOWNERS  # Ignoring the CODEOWNERS file in the secrets directory

      - name: Check for Relevant Changes
        id: check_changes
        run: |
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          relevant_changes="false"
          for file in "${modified_files[@]}"; do
            # Extract the folder name from the file path
            path_components=(${file//\// })
            folder_name=${path_components[2]}  # Adjust based on your directory structure

            if [[ $file == secrets/${{ matrix.environment }}/$folder_name/* ]]; then
              relevant_changes="true"
              break
            fi
          done
          echo "RELEVANT_CHANGES=$relevant_changes" >> $GITHUB_ENV

      # Set environment variables based on the matrix environment
      - if: env.RELEVANT_CHANGES == 'true'
        name: Set environment variables for ${{ matrix.environment }} environment
        run: |
          case ${{ matrix.environment }} in
            sandbox)
              VAULT_ADDR="${{ secrets.SANDBOX_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.SANDBOX_VAULT_TOKEN }}"
              ;;
            staging)
              VAULT_ADDR="${{ secrets.STAGING_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.STAGING_VAULT_TOKEN }}"
              ;;
            production)
              VAULT_ADDR="${{ secrets.PRODUCTION_VAULT_ADDR }}"
              VAULT_TOKEN="${{ secrets.PRODUCTION_VAULT_TOKEN }}"
              ;;
            *)
              echo "Unsupported environment: ${{ matrix.environment }}"
              exit 1
              ;;
          esac
          echo "VAULT_ADDR=$VAULT_ADDR" >> $GITHUB_ENV
          echo "VAULT_TOKEN=$VAULT_TOKEN" >> $GITHUB_ENV

      - if: env.RELEVANT_CHANGES == 'true'
        name: Decrypt Double-Dotted Secret Files
        run: |
          set -e
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          for file in "${modified_files[@]}"; do
            if [[ $(basename "$file") =~ \..+\.yaml$ ]]; then
              # Extract the folder name from the file path
              path_components=(${file//\// })
              folder_name=${path_components[2]}  # Adjust based on your directory structure

              decrypted_directory="secrets/${{ matrix.environment }}/$folder_name/decrypted"
              mkdir -p "$decrypted_directory"
              decrypted_file_path="$decrypted_directory/$(basename $file)"
              flag_file_path="$decrypted_directory/$(basename $file).decrypted"

              echo "Decrypting double-dot file: $file"
              if sops --config configs/v2_sops.yaml --decrypt $file > $decrypted_file_path; then
                # Create a flag file to indicate successful decryption
                touch "$flag_file_path"
              fi
            fi
          done

      - if: env.RELEVANT_CHANGES == 'true'
        name: Process Secret Files
        run: |
          set -e
          IFS=' ' read -r -a modified_files <<< "${{ steps.files.outputs.all_changed_files }}"
          for file in "${modified_files[@]}"; do
            if [[ $file == secrets/${{ matrix.environment }}/* ]]; then
              # Extract the folder name from the file path
              path_components=(${file//\// })
              folder_name=${path_components[2]}  # Adjust based on your directory structure

              decrypted_directory="secrets/${{ matrix.environment }}/$folder_name/decrypted"  # Update as needed
              decrypted_file_path="$decrypted_directory/$(basename $file)"
              flag_file_path="$decrypted_directory/$(basename $file).decrypted"

              if [[ -f "$flag_file_path" ]]; then
                # Process decrypted file
                echo "Processing decrypted file: $decrypted_file_path"

                # Convert YAML to JSON using yq
                pip install yq
                yq -r . "$decrypted_file_path" > temp.json
                # yq -r . "$decrypted_file_path" > "${decrypted_file_path%.yaml}.json"

                # Wrap the JSON output in {"data": { ... }}
                jq '{data: .}' temp.json > "${decrypted_file_path%.yaml}.json"

                # Debug output the contents of the JSON file for debugging
                # echo "Converted JSON content:"
                # cat "${decrypted_file_path%.yaml}.json"

                # Construct the Vault path
                filename_without_extension="$(basename $decrypted_file_path .yaml)"
                IFS='.' read -r secret_name sub_path <<< "$filename_without_extension"
                vault_path="secret-v2/data/$secret_name/$sub_path"
                echo "Uploading to Vault at path: $vault_path"

                # Upload to Vault
                curl -H "X-Vault-Token: $VAULT_TOKEN" \
                      -H "Content-Type: application/json" \
                      --request POST \
                      --data @"${decrypted_file_path%.yaml}.json" \
                      $VAULT_ADDR/v1/$vault_path
              else
                # File not decrypted, use sops publish
                echo "Publishing secret using sops for file: $file"
                sops publish -y $file
              fi
            fi
          done
```


## Setup and Contributions

To contribute to this repository:

1. **Clone the Repository**: Use Git to clone the repository to your local machine.
2. **Follow Coding Standards**: Ensure code changes adhere to the standards specified in the repository.
3. **Run Tests**: Execute any existing tests to verify that your changes do not break existing functionalities.
4. **Create a Pull Request**: Submit your changes for review via a pull request. Ensure your PR includes a clear description of the changes and any relevant issue numbers.
5. **Code Review**: Wait for code review and address any feedback provided.


## Disclaimer

This documentation provides a general overview and guidance for the `infra-secrets` repository. It is essential to refer to the specific files and scripts within the repository for detailed and context-specific instructions. The users of this repository are responsible for complying with all applicable policies and guidelines related to security and data handling.


[def]: ttps://meetearnest.atlassian.net/wiki/spaces/EN/pages/2717089856/Migrate+from+aws-sts-token-generator+to+saml2aw