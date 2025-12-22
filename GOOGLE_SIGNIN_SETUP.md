# Google Sign-In Setup Instructions

## EASIEST METHOD - Get Client ID from Firebase Console:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: **MC-Flutter-Project**
3. Click **Authentication** (👥 icon) in the left sidebar
4. Click the **Sign-in method** tab at the top
5. Find **Google** in the providers list and click on it
6. Click **Enable** toggle (if not already enabled)
7. You'll see **Web SDK configuration** section
8. Copy the **Web client ID** shown there (format: XXXXX.apps.googleusercontent.com)
9. Click **Save**

## Alternative Method - From Google Cloud Console:

If you need to configure authorized domains:

1. Go to: https://console.cloud.google.com/
2. Select your Firebase project
3. Navigate to: **APIs & Services** → **Credentials**
4. Find **OAuth 2.0 Client IDs**
5. Click on the **Web client (auto created by Google Service)**
6. Copy the **Client ID** (format: XXXXX.apps.googleusercontent.com)
7. Also add to **Authorized JavaScript origins**:
   - http://localhost
   - http://localhost:5000
   - http://localhost:7357
8. Add to **Authorized redirect URIs**:
   - http://localhost/__/auth/handler
   - http://localhost:5000/__/auth/handler

## Update Your App:

1. Open `web/index.html`
2. Find this line:
   ```html
   <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
   ```
3. Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID

## Test:

Run the app after updating:
```bash
flutter run -d chrome
```

Click "Sign up with Google" or "Sign in with Google" button.
