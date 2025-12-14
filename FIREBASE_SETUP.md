# Firebase Configuration Setup

## Important: Keep API Keys Secret!

The `lib/firebase_options.dart` file contains sensitive Firebase configuration and is **NOT** tracked by Git (see `.gitignore`).

## Setup Instructions for New Developers

### Step 1: Get Your Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `device-streaming-40403813`
3. Go to **Project Settings** (gear icon)
4. Select the **Android** app
5. Download or copy the configuration details:
   - API Key
   - App ID
   - Messaging Sender ID
   - Project ID
   - Storage Bucket

### Step 2: Create firebase_options.dart

1. Copy the template file:
   ```
   cp lib/firebase_options.template.dart lib/firebase_options.dart
   ```

2. Open `lib/firebase_options.dart` and replace the placeholder values:
   ```dart
   const FirebaseOptions(
     apiKey: 'YOUR_API_KEY_HERE',           // Replace with your API Key
     appId: 'YOUR_APP_ID_HERE',              // Replace with your App ID
     messagingSenderId: 'YOUR_MESSAGING_SENDER_ID_HERE',
     projectId: 'YOUR_PROJECT_ID_HERE',
     storageBucket: 'YOUR_STORAGE_BUCKET_HERE',
   )
   ```

3. Save the file (it won't be committed to Git)

### Step 3: Get google-services.json

1. In Firebase Console → **Project Settings** → **Google Play** tab
2. Download `google-services.json`
3. Place it in: `android/app/google-services.json`
4. This file is also gitignored for security

### Step 4: Run the App

```bash
flutter pub get
flutter run
```

## Security Notes

✅ **These files are protected:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Any other sensitive configuration

❌ **Never commit these to Git:**
- API keys
- Service account credentials
- Private keys

## If You Already Pushed API Keys

If you've already committed sensitive data to GitHub:

1. **Immediately rotate your Firebase keys** in the Firebase Console
2. Use a tool like `git-filter-branch` or BFG Repo-Cleaner to remove the history
3. Force push the cleaned history

## For CI/CD Deployment

If deploying with GitHub Actions or similar:

1. Add secrets to your GitHub repository settings
2. Use environment variables in your workflow
3. Generate `firebase_options.dart` during the build process

Example (GitHub Actions):
```yaml
- name: Create Firebase Options
  run: |
    cat > lib/firebase_options.dart << EOF
    // File contents with secrets from environment variables
    EOF
```
