# Lakhaan Website

Landing page for Lakhaan GST Invoice Generator.

## Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Firebase Setup

Create a Firebase project and enable Firestore. Then create a `.env.local` file:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
```

### 3. Firestore Rules

Enable Firestore and set rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 4. Run Development
```bash
npm run dev
```

### 5. Build for Production
```bash
npm run build
```

Output will be in `out/` folder - deploy to Vercel, Netlify, or any static hosting.

## Deploy to Vercel

```bash
npm i -g vercel
vercel
```

Set environment variables in Vercel dashboard.
