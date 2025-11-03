# 🧹 Pre-Publication Cleanup Checklist

Before pushing this repository to GitHub public, follow these steps:

## ✅ Step 1: Verify Sensitive Files are Excluded

Run this command to check what will be committed:

```bash
git status
git ls-files
```

**Make sure these files are NOT in the list:**
- `terraform/environments/dev/terraform.tfvars`
- `terraform/environments/prd/terraform.tfvars`
- `terraform/environments/dev/backend.tfvars`
- `terraform/environments/prd/backend.tfvars`
- `terraform/stacks/iam-gcp/dev.tfvars`
- `terraform/stacks/iam-gcp/prd.tfvars`
- `terraform/stacks/iam-github/common.tfvars`
- Any `*.tfstate` files
- Any `*-sa-key.json` files
- Any `.env` files

## ✅ Step 2: Remove Files from Git History (if already committed)

If sensitive files were already committed, remove them from history:

```bash
# Remove specific file from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch terraform/environments/dev/terraform.tfvars" \
  --prune-empty --tag-name-filter cat -- --all

# For multiple files, create a list
cat > files_to_remove.txt << EOF
terraform/environments/dev/terraform.tfvars
terraform/environments/prd/terraform.tfvars
terraform/environments/dev/backend.tfvars
terraform/environments/prd/backend.tfvars
terraform/stacks/iam-gcp/dev.tfvars
terraform/stacks/iam-gcp/prd.tfvars
terraform/stacks/iam-github/common.tfvars
EOF

# Remove all listed files
while read file; do
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch $file" \
    --prune-empty --tag-name-filter cat -- --all
done < files_to_remove.txt

# Clean up
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Alternative (Recommended): Use BFG Repo-Cleaner**

```bash
# Install BFG
# brew install bfg  # on macOS
# Or download from: https://rtyley.github.io/bfg-repo-cleaner/

# Backup your repo first!
cd ..
cp -r IAO IAO-backup

# Clean the repo
cd IAO
bfg --delete-files terraform.tfvars
bfg --delete-files backend.tfvars
bfg --delete-files '*.tfvars' --no-blob-protection

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## ✅ Step 3: Verify Example Files Exist

Make sure these example files are present:

```bash
ls -la terraform/environments/dev/terraform.tfvars.example
ls -la terraform/environments/prd/terraform.tfvars.example
ls -la terraform/environments/dev/backend.tfvars.example
ls -la terraform/environments/prd/backend.tfvars.example
ls -la terraform/stacks/iam-gcp/dev.tfvars.example
ls -la terraform/stacks/iam-gcp/prd.tfvars.example
ls -la terraform/stacks/iam-github/common.tfvars.example
```

## ✅ Step 4: Update GitHub Workflows (if needed)

Check that GitHub workflow files don't contain sensitive data:

```bash
grep -r "infra-as-code-tek" .github/workflows/
grep -r "lenny-iac" .github/workflows/
grep -r "@gmail.com" .github/workflows/
```

If found, replace with placeholders or use GitHub Secrets.

## ✅ Step 5: Search for Any Remaining Sensitive Data

```bash
# Search for project IDs
grep -r "infra-as-code-tek" . --exclude-dir=.git --exclude-dir=node_modules
grep -r "lenny-iac" . --exclude-dir=.git --exclude-dir=node_modules

# Search for emails
grep -r "@gmail.com" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.example"

# Search for bucket names
grep -r "lenny.*bucket" . --exclude-dir=.git --exclude-dir=node_modules

# Search for GitHub usernames
grep -r "Linnchoeuh" . --exclude-dir=.git --exclude-dir=node_modules
grep -r "lenny-vigeon" . --exclude-dir=.git --exclude-dir=node_modules
```

## ✅ Step 6: Add Security Documentation

Make sure these files are present and correct:

```bash
cat SECURITY.md
cat .gitignore
```

## ✅ Step 7: Create a Fresh Commit

```bash
git add .
git commit -m "chore: prepare repository for public release

- Remove all sensitive data
- Add example configuration files
- Update documentation with placeholders
- Add security guidelines"
```

## ✅ Step 8: Create a New Clean Repository (Recommended)

For maximum security, create a fresh repository without history:

```bash
# Create a new directory
mkdir IAC-public
cd IAC-public

# Copy only necessary files (excluding .git)
rsync -av --progress ../IAO/ . \
  --exclude .git \
  --exclude node_modules \
  --exclude .terraform \
  --exclude '*.tfvars' \
  --exclude '*.tfstate*' \
  --exclude '*-sa-key.json'

# Initialize new git repo
git init
git add .
git commit -m "initial commit: Infrastructure as Code project"

# Add remote and push
git remote add origin https://github.com/your-org/your-repo.git
git branch -M main
git push -u origin main
```

## ✅ Step 9: Double Check on GitHub

After pushing:

1. Go to your repository on GitHub
2. Use GitHub's search to look for sensitive data
3. Check the "Insights > Network" to ensure no sensitive commits
4. Review all files in the web interface

## ✅ Step 10: Enable Security Features

On GitHub:

1. Enable "Dependabot alerts"
2. Enable "Secret scanning"
3. Enable "Code scanning"
4. Add branch protection rules
5. Set up required reviews for PRs

## 🚨 If You Find Sensitive Data After Publishing

If you accidentally published sensitive data:

1. **Immediately** rotate all exposed credentials
2. Delete the repository from GitHub
3. Follow Step 8 to create a clean repo
4. Re-publish with cleaned data
5. Update all affected services/keys

## 📞 Emergency Contacts

If you exposed:
- **GCP Service Account Keys**: Disable them in GCP Console immediately
- **GitHub Tokens**: Revoke them in GitHub Settings
- **Secrets**: Rotate them in Google Secret Manager

---

**Remember**: Once data is pushed to GitHub, consider it compromised, even if you delete it immediately. Always clean first, push later!
