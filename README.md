# infra-vault-secrets
Repo for managing vault secrets

# Shift-Left with SAML, AWS IAM, and AGE Keys

This guide provides a step-by-step walkthrough for setting up pre-commit hooks, managing secrets, and integrating SAML-based authentication with AWS IAM for KMS access. This enables a "shift-left" approach, empowering Earnest engineers to self-serve their respective secrets securely.

## Table of Contents

1. [Pre-commit and Pre-requisites](#pre-commit-and-pre-requisites)
2. [Managing Secrets](#managing-secrets)
3. [SAML Authentication with AWS IAM](#saml-authentication-with-aws-iam)
4. [Export AGE Keys for Self-Service](#export-age-keys-for-self-service)

---

## SAML Authentication with AWS IAM using OKTA

Integrating Okta as a SAML Identity Provider (IdP) with AWS IAM allows for secure, federated access to AWS resources, including KMS. This is particularly useful for implementing a "shift-left" approach where engineers can self-serve without compromising on security.

### Steps

1. **Okta Setup**:
    - Create an Okta account and set up an AWS application in Okta.
    - Configure SAML settings and note down the SAML 2.0 endpoint and the identity provider Issuer URL.

2. **AWS IAM Configuration**:
    - In AWS IAM, create a new SAML Identity Provider and upload the metadata XML from Okta.
    - Create a new IAM role and associate it with the SAML IdP. Attach policies that allow access to KMS.

3. **Okta User and Group Setup**:
    - Assign AWS roles to Okta groups.
    - Add users to these Okta groups so they can assume the corresponding AWS roles.

4. **SAML Assertion and AWS Login**:
    - Users can now log in to the AWS console via Okta or use the AWS CLI to assume roles.

```bash
# Use the AWS CLI to assume a role via Okta
aws sts assume-role-with-saml --role-arn "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME" --principal-arn "arn:aws:iam::ACCOUNT_ID:saml-provider/Okta" --saml-assertion "ENCODED_SAML_ASSERTION_FROM_OKTA"

# e.g., connection using saml2aws cli tool

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
Note that it will expire at 2023-10-31 07:57:41 -0700 PDT
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile Okta-Sandbox-Administrator ec2 describe-instances).
```


## Pre-commit and Pre-requisites

```bash
# Clone the repository
git clone https://github.com/meetearnest/infra-secrets.git
cd infra-secrets

# Install pre-commit
pip install pre-commit

# Install the git hooks
pre-commit install
```

# Managing Secrets
##  Create a New Secret
```bash
# Navigate to the secrets folder
# ENV e.g., sandobx, staging, production
cd secrets/<ENV>/infra

# Follow the 
# Create a new YAML file for your secret
echo "api_key: '123456789'" > new-secret.yaml

# Encrypt the secret using SOPS
sops --encrypt --in-place new-secret.yaml
```

## Modify an Existing Secret

```bash
# Decrypt the existing secret file first
sops --decrypt --in-place existing-secret.yaml

# Modify the YAML file
vim existing-secret.yaml

# Re-encrypt the modified file
sops --encrypt --in-place existing-secret.yaml
```


