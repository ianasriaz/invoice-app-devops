# DevOps Pipeline Setup Guide

This guide explains how to configure the CI/CD pipeline with GitHub Actions, Firebase Hosting, and Trello integration.

## What This Pipeline Does

1. **On every push/PR to main/develop:**
   - Runs Flutter tests
   - Checks code formatting
   - Analyzes code quality

2. **On push to main branch:**
   - Builds Flutter web (production)
   - Deploys to Firebase Hosting
   - Updates Trello board automatically:
     - **Success:** Move card to "Done" list
     - **Failure:** Move card to "In Progress" list

## GitHub Secrets Setup (REQUIRED)

You must add 6 secrets to your GitHub repository for the pipeline to work.

### Step 1: Go to GitHub Secrets Page
1. Navigate to: https://github.com/ianasriaz/invoice-app-devops
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Step 2: Add Each Secret

Add these 6 secrets one by one:

#### 1. FIREBASE_SERVICE_ACCOUNT
**Name:** `FIREBASE_SERVICE_ACCOUNT`  
**Value:** Paste the entire JSON from your Firebase Service Account file (the one you downloaded earlier from Firebase Console → Project Settings → Service Accounts → Generate new private key).

It should start with:
```json
{
  "type": "service_account",
  "project_id": "gdgcloud-480509",
  ...
}
```

⚠️ **DO NOT commit this JSON to GitHub.** Only paste it directly in the GitHub Secrets UI.

#### 2. TRELLO_API_KEY
**Name:** `TRELLO_API_KEY`  
**Value:** `ec095d3af273c637dea684e5a70ad` + your 3 digits (complete it)

#### 3. TRELLO_TOKEN
**Name:** `TRELLO_TOKEN`  
**Value:** `ATTA9ac64c872025f4f0e9678f020bf125bdfb9395ccb9eab4c82b0c08f3448fc48d53E26` + your 3 digits (complete it)

#### 4. TRELLO_BOARD_ID
**Name:** `TRELLO_BOARD_ID`  
**Value:** `694951faa7d6cc8841fe7bae`

#### 5. TRELLO_TODO_LIST_ID
**Name:** `TRELLO_TODO_LIST_ID`  
**Value:** `694951faa7d6cc8841fe7be9`

#### 6. TRELLO_INPROGRESS_LIST_ID
**Name:** `TRELLO_INPROGRESS_LIST_ID`  
**Value:** `694951faa7d6cc8841fe7bea`

#### 7. TRELLO_DONE_LIST_ID
**Name:** `TRELLO_DONE_LIST_ID`  
**Value:** `694951faa7d6cc8841fe7beb`

## How to Get Your Actual Trello Board URL

1. Open your Trello board in browser
2. Copy the URL from the address bar (e.g., `https://trello.com/b/ABC123/invoice-app-devops`)
3. Replace `https://trello.com/b/???/invoice-app-devops` in [lib/screens/drawer.dart](../lib/screens/drawer.dart) line 182 with your actual URL
4. Commit and push this change

## Pipeline Workflow

### On Every Push to Main:
```
1. Run Tests (Ubuntu)
   ├─ Check formatting
   ├─ Analyze code
   └─ Run unit tests

2. Build Web (Ubuntu) - if tests pass
   └─ Build Flutter web for production

3. Deploy to Firebase (Ubuntu) - if build succeeds
   └─ Upload to Firebase Hosting

4. Update Trello (Ubuntu) - if deploy succeeds
   └─ Move card to "Done" list
   OR
   └─ Move card to "In Progress" list (if any step fails)
```

## Monitoring Your Pipeline

1. Go to your GitHub repo: https://github.com/ianasriaz/invoice-app-devops
2. Click **Actions** tab
3. See all workflow runs and their status
4. Click a run to see detailed logs

## Making Changes to the Pipeline

The workflow file is at: `.github/workflows/ci-deploy.yml`

To modify:
1. Edit the file in your repo
2. Commit and push to main
3. The new workflow will run on the next push

## Trello Integration Details

**What Happens:**
- Each build creates a card named: `Build #[commit-hash] - [branch-name]`
- On **success**: Card is moved to **Done** list (green label)
- On **failure**: Card is moved to **In Progress** list (red label)
- Card includes: commit hash, branch, actor, and timestamp

**Example Card:**
```
Build #abc1234 - main
✓ Build Status: SUCCESS
  Commit: abc123456789...
  Branch: refs/heads/main
  Actor: ianasriaz
  Timestamp: 2024-12-22T15:30:45.123Z
```

## Troubleshooting

### Pipeline fails with "Invalid credentials"
→ Check that all 7 secrets are added correctly to GitHub

### Deployment fails
→ Check logs in GitHub Actions tab for specific error

### Trello card not updating
→ Verify Trello API Key and Token are complete with your 3 final digits

## Next Steps

1. ✅ Add all 7 secrets to GitHub (see above)
2. ✅ Update Trello board URL in drawer.dart
3. ✅ Commit and push changes to main
4. ✅ Go to Actions tab to watch your first build
5. ✅ Visit `https://gdgcloud-480509.web.app` to see your deployed app
