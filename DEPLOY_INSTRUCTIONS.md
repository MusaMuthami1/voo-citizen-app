# Firebase Hosting Deployment Instructions

Since the Firebase CLI is not installed in your environment, please follow these steps to deploy your APK:

## 1. Install Firebase CLI (if not installed)

Open a terminal and run:

```bash
npm install -g firebase-tools
```

## 2. Login to Firebase

```bash
firebase login
```

## 3. Select Your Project

```bash
firebase use --add
```

_Select your "voo-citizen-app" project from the list._

## 4. Deploy

```bash
firebase deploy --only hosting
```

## 5. Get Your Download Link

After deployment, Firebase will show a "Hosting URL" (e.g., `https://your-project.web.app`).

Your APK download link will be:
`https://your-project.web.app/VOO-Citizen-App-v9.5.apk`

## 6. Clean Up Test Data

Before launching, run the `wipe_test_data.sql` script in the Supabase SQL Editor to remove any "test" announcements, issues, or messages.

## 7. Update Database

Once you have the URL, update your database using the SQL file provided in the repository, replacing `YOUR_PROJECT_ID` with your actual project ID.
