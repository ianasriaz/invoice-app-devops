# 🚀 INVOICO DevOps Pipeline - Interactive Guide

Welcome! This guide walks you through how our automated DevOps pipeline works, how to trigger it, and how to monitor deployments.

---

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [Pipeline Overview](#pipeline-overview)
3. [How to Trigger a Deployment](#how-to-trigger-a-deployment)
4. [Pipeline Stages Explained](#pipeline-stages-explained)
5. [Trello Integration](#trello-integration)
6. [Email Notifications](#email-notifications)
7. [Monitoring & Logs](#monitoring--logs)
8. [Troubleshooting](#troubleshooting)
9. [Architecture Diagram](#architecture-diagram)

---

## 🚀 Quick Start

### I want to deploy my code. What do I do?

1. **Go to GitHub Actions**
   - Navigate to: https://github.com/ianasriaz/invoice-app-devops/actions
   - Select: **🚀 DevOps Pipeline - Agent Task Flow**

2. **Click "Run workflow"**
   - A form will appear asking for:
     - **📝 Trello Card Title** – What are you deploying? (e.g., "Add login feature")
     - **🎫 Trello Card ID** – Copy from your Trello card URL
     - **⏭️ Skip Tests** – Leave unchecked unless it's urgent

3. **Click "Run workflow"** button

4. **Watch the pipeline execute** (takes ~5-10 minutes)

5. **Check your email** for deployment confirmation or errors

---

## 📊 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                  🚀 INVOICO DEVOPS PIPELINE                         │
└─────────────────────────────────────────────────────────────────────┘

Input: Card Title, Card ID, Skip Tests
         ↓
    ✅ Confirm Ready
         ↓
    📦 Code Pushed (Verify repo state)
         ↓
    🧪 Test & Build (Format, Analyze, Test, Build Web)
         ↓
    🌐 Deploy to Cloud (Firebase Hosting)
         ↓
    🎯 Update Trello (Mark card as "Deployed")
         ↓
    📧 Send Notification (Success or Failure email)
         ↓
    ✨ Done!
```

---

## 🎬 How to Trigger a Deployment

### Method 1: GitHub Actions UI (Easiest)

```
GitHub → Actions Tab
  ↓
Select "🚀 DevOps Pipeline - Agent Task Flow"
  ↓
Click "Run workflow"
  ↓
Fill in the form:
  - Card Title: "Fix splash screen bug"
  - Card ID: (from Trello)
  - Skip Tests: [ ] (leave unchecked)
  ↓
Click "Run workflow"
```

### Method 2: Using GitHub CLI

```bash
gh workflow run agent-task.yml \
  -f card_title="My Feature" \
  -f card_id="YOUR_CARD_ID" \
  -f skip_tests=false
```

### Input Details

| Input | Description | Required | Example |
|-------|-------------|----------|---------|
| **Card Title** | Name of the Trello card being deployed | Yes | "Add invoice export to PDF" |
| **Card ID** | Unique Trello card identifier | Yes | `694951faa7d6cc884a1` |
| **Skip Tests** | Bypass test suite (use for hotfixes only) | No | false |

---

## 🔧 Pipeline Stages Explained

### Stage 1: ✅ Confirm Ready to Deploy
**What it does:** Displays the deployment request details

```
Input Variables:
  • Task Title (from Trello)
  • Card ID
  • Commit SHA
  • GitHub Actor (who triggered it)
  • Branch
  • Skip Tests flag
```

**Why:** Ensures you're deploying the right thing and creates an audit trail.

---

### Stage 2: 📦 Code Pushed
**What it does:** Verifies the code is committed to main branch

```
Checks:
  ✅ Commit hash is valid
  ✅ Repository is accessible
  ✅ Code is on main branch
```

**Why:** Prevents deploying uncommitted changes.

---

### Stage 3: 🧪 Test & Build
**What it does:** Validates and builds your Flutter web app

```
Steps in order:
  1. 📦 Install dependencies (flutter pub get)
  2. 🎨 Format check (dart format)
  3. 🔍 Code analysis (dart analyze)
  4. 🧪 Run tests (if not skipped)
  5. 🏗️  Build production bundle (flutter build web --release)
  6. 📤 Upload artifact to GitHub
```

**If it fails:**
- Check format errors: `dart format --output=none .`
- Check analysis: `dart analyze .`
- Run tests locally: `flutter test`

---

### Stage 4: 🚀 Deploy to Cloud
**What it does:** Uploads the built app to Google Firebase Hosting

```
Deployment Target:
  🌐 https://gdgcloud-480509.web.app

Environment:
  • Project ID: gdgcloud-480509
  • Hosting: Firebase Hosting
  • CDN: Google Cloud global edge network
  • SSL: Automatic HTTPS
```

**Why:** Your app is now live and accessible worldwide.

---

### Stage 5: 🎯 Update Trello Status
**What it does:** Automatically moves your card to "Deployed" list

```
Trello Updates:
  ✅ Card moved from "Ready" to "Deployed"
  ✅ Comment added with:
     - Commit SHA
     - GitHub Actor
     - Live URL
     - Timestamp
```

**Why:** Keeps your team synchronized without manual updates.

---

### Stage 6: 📧 Email Notification
**What it does:** Sends success or failure email to the team

```
Success Email Contains:
  • Deployment status (✅ SUCCESS)
  • Live URL
  • Task details
  • All pipeline stage results
  • Links to logs

Failure Email Contains:
  • Deployment status (❌ FAILED)
  • Which stage failed
  • Troubleshooting steps
  • Link to detailed logs
```

**Why:** Keeps everyone informed without checking GitHub constantly.

---

## 🎯 Trello Integration

### How It Works

1. **Before Deployment:** Card should be in "Ready" list
2. **During Deployment:** Pipeline reads card ID from input
3. **After Success:** Card moves to "Deployed" list automatically
4. **After Failure:** Card moves to failed state with error comment

### Trello Board Setup

```
Lists on your Trello board:
├── 📋 To Do
├── 🔄 In Progress
├── ✅ Ready (cards here can be deployed)
├── 🚀 Deployed (automatically updated)
└── ❌ Failed (auto-marked if deployment fails)
```

### How to Get Card ID

1. Open your Trello card in browser
2. Look at the URL: `https://trello.com/c/CARD_ID/...`
3. Copy the `CARD_ID` portion
4. Use it in the workflow input

---

## 📧 Email Notifications

### Setup Required

Ensure these secrets are set in GitHub:
- `SMTP_SERVER` – Email provider server (e.g., `smtp.purelymail.com`)
- `SMTP_PORT` – Port (usually `465` or `587`)
- `SMTP_USERNAME` – Your email address
- `SMTP_PASSWORD` – Email password or app-specific password
- `NOTIFY_EMAIL_FROM` – Sender address (e.g., `devops@yourcompany.com`)
- `NOTIFY_EMAIL_TO` – Recipient email (e.g., `team@yourcompany.com`)

### Where to Set Secrets

1. Go to: https://github.com/ianasriaz/invoice-app-devops/settings/secrets/actions
2. Click "New repository secret"
3. Add each secret above

### What You'll Receive

**✅ Success Email**
```
Subject: ✅ Deployment Complete: Add login feature
From: DevOps Pipeline <devops@company.com>
To: team@company.com

Contains:
- Live URL: https://gdgcloud-480509.web.app
- Commit hash
- All pipeline stage results
- Task details from Trello
```

**❌ Failure Email**
```
Subject: ❌ Deployment Failed: Add login feature
From: DevOps Pipeline <devops@company.com>
To: team@company.com

Contains:
- Which stage failed
- Error details
- Troubleshooting steps
- Link to detailed logs
```

---

## 📊 Monitoring & Logs

### View Pipeline Progress

1. **Real-time:** https://github.com/ianasriaz/invoice-app-devops/actions
2. **Select workflow run** (newest at top)
3. **Watch logs update** as stages execute

### Download Build Artifact

```
In the workflow run:
  Artifacts section
    → web-build-<COMMIT_SHA> (7-day retention)
      → build/
        → web/
          → index.html (your deployed app)
```

### Common Log Patterns

**Success Pattern:**
```
✅ Stage 1: Confirm Ready ............ DONE
✅ Stage 2: Code Pushed .............. DONE
✅ Stage 3: Test & Build ............. DONE
✅ Stage 4: Deploy to Cloud .......... DONE
✅ Stage 5: Update Trello ............ DONE
✅ Stage 6: Email Notification ....... DONE
```

**Failure Pattern:**
```
✅ Stage 1: Confirm Ready ............ DONE
✅ Stage 2: Code Pushed .............. DONE
❌ Stage 3: Test & Build ............. FAILED
  └─ Error: dart analyze found issues
  └─ Solution: Run `dart analyze .` locally
```

---

## 🔧 Troubleshooting

### Problem: Build fails with "Flutter dependency error"

**Solution:**
```bash
# Locally:
flutter pub get
flutter pub upgrade
git add pubspec.lock
git commit -m "chore: update dependencies"
git push

# Then re-run workflow
```

---

### Problem: Code analysis fails

**Solution:**
```bash
# Check what's wrong:
dart analyze .

# Auto-fix issues:
dart fix --apply

# Format code:
dart format .

# Commit and push:
git add .
git commit -m "chore: fix linting issues"
git push
```

---

### Problem: Tests fail

**Options:**

**Option A: Fix the tests**
```bash
# Run tests locally:
flutter test

# Fix failing tests, then:
git add .
git commit -m "fix: update tests"
git push
```

**Option B: Skip tests for urgent hotfix**
```
When running workflow:
  Set "Skip Tests" = ✅ (checked)
  
Warning: Only use this for true emergencies!
```

---

### Problem: Trello card doesn't update

**Check:**
1. Is the card ID correct? (Copy from card URL)
2. Are Trello secrets set?
   - `TRELLO_API_KEY`
   - `TRELLO_TOKEN`
   - `TRELLO_BOARD_ID`
   - `TRELLO_DEPLOYED_LIST_ID`
3. Run workflow and check logs for Trello step

**If still stuck:**
```bash
# Check secrets are visible:
gh secret list

# Look for TRELLO_* secrets
```

---

### Problem: Email not received

**Check:**
1. Are all email secrets set?
   ```
   - SMTP_SERVER
   - SMTP_PORT
   - SMTP_USERNAME
   - SMTP_PASSWORD
   - NOTIFY_EMAIL_FROM
   - NOTIFY_EMAIL_TO
   ```

2. Check spam/junk folder

3. Verify credentials work (test outside GitHub):
   ```bash
   # Use your email client to test SMTP
   ```

4. Check email step logs:
   - GitHub Actions → Workflow run
   - Look for "📧 Email Team" step
   - Expand and read output

---

### Problem: "Deployment successful but site shows old version"

**Solution:**

Clear browser cache:
```javascript
// Open DevTools (F12) on https://gdgcloud-480509.web.app
// Go to Application tab → Clear Storage → Clear all
// Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R on Mac)
```

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Your Code Repository                            │
│                  (GitHub: invoice-app-devops)                           │
│                                                                         │
│  Files that trigger pipeline:                                          │
│  • lib/screens/splash_screen.dart                                      │
│  • lib/main.dart                                                       │
│  • pubspec.yaml                                                        │
│  • .github/workflows/agent-task.yml (the pipeline itself)             │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
                    🚀 GitHub Actions Workflow
                    (runs on ubuntu-latest)
                                    ↓
                    ┌─────────────────────────────┐
                    │   Confirm Ready             │
                    │   Code Pushed               │
                    │   Test & Build              │
                    │   Deploy to Cloud           │
                    │   Update Trello             │
                    │   Send Email                │
                    └─────────────────────────────┘
                                    ↓
                ┌───────────────────┬───────────────────┐
                ↓                   ↓                   ↓
         🌐 Firebase Hosting   🎯 Trello Board     📧 Email
         (Live App)            (Card Status)       (Notification)
         
         https://gdgcloud-    Card → Deployed    team@company.com
         480509.web.app
```

---

## 📚 Quick Reference

### URLs

| Resource | URL |
|----------|-----|
| Live App | https://gdgcloud-480509.web.app |
| GitHub Repo | https://github.com/ianasriaz/invoice-app-devops |
| Actions | https://github.com/ianasriaz/invoice-app-devops/actions |
| Workflow File | [.github/workflows/agent-task.yml](.github/workflows/agent-task.yml) |
| Trello Board | https://trello.com/b/YOUR_BOARD_ID |

### Commands

```bash
# Test locally before deploying
flutter analyze .
dart format --output=none .
flutter test
flutter build web --release

# View pipeline logs
gh run list --workflow=agent-task.yml
gh run view <RUN_ID>

# Deploy manually (not recommended, use UI instead)
gh workflow run agent-task.yml \
  -f card_title="Feature Name" \
  -f card_id="CARD_ID" \
  -f skip_tests=false
```

---

## ❓ FAQ

**Q: How long does deployment take?**
A: Typically 5-10 minutes (build + deploy time varies with code size)

**Q: Can I deploy multiple times a day?**
A: Yes! Each run is independent. Check Trello board and logs to avoid conflicts.

**Q: What if deployment fails partway through?**
A: Previous stages are logged. Email will tell you which stage failed. Fix the issue locally and re-run.

**Q: How do I test the pipeline without deploying?**
A: Run tests locally first: `flutter test && flutter analyze .`

**Q: Can I rollback a deployment?**
A: Firebase Hosting doesn't auto-rollback. Deploy the previous commit to revert: `git revert <COMMIT_SHA>` then deploy.

**Q: Who gets notified?**
A: Anyone in the `NOTIFY_EMAIL_TO` secret (you can add multiple: `email1@company.com, email2@company.com`)

---

## 🎓 Learning Path

### Beginner
1. Read "Quick Start" section
2. Trigger your first deployment
3. Watch the logs

### Intermediate
1. Read "Pipeline Stages Explained"
2. Understand Trello integration
3. Set up email notifications

### Advanced
1. Edit the workflow file
2. Add custom stages
3. Integrate with other tools (Slack, Discord, etc.)

---

## 📞 Need Help?

1. **Check the logs first** – Most answers are there
2. **Read Troubleshooting** section above
3. **Review the workflow file** – Comments explain each step
4. **Check GitHub Issues** – Your question might be answered there

---

## 🎉 You're All Set!

Your deployment pipeline is ready to use. Good luck with your deployments!

**Next Steps:**
1. ✅ Bookmark the GitHub Actions page
2. ✅ Add team members to repository
3. ✅ Set up email notifications
4. ✅ Create your first Trello card
5. ✅ Run your first deployment!

---

*Last updated: December 23, 2025*
*Pipeline: 🚀 DevOps Pipeline - Agent Task Flow*
