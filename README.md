# VOO Citizen App

A mobile Android application for citizens to report community issues with photo uploads, AI-powered analysis, and push notifications.

## Tech Stack
- **Mobile**: Flutter (Android)
- **Backend**: Node.js/Express
- **Database**: MongoDB
- **Images**: Cloudinary
- **AI**: OpenAI GPT-4 Vision
- **Notifications**: Firebase Cloud Messaging

## Features
- 📷 Report issues with photos (up to 5 images)
- 🤖 AI-powered image analysis and categorization
- 📍 GPS location capture
- 🔔 Push notifications for status updates
- 🔒 Secure authentication with Terms & Policy
- 📊 Track issue status in real-time

## Project Structure
```
VOOAPP/
├── api/                    # Backend API
│   ├── src/
│   │   ├── index.js        # Main server file
│   │   └── services/       # OpenAI, Cloudinary, Firebase
│   ├── .env                # Environment variables
│   └── package.json
│
└── mobile/                 # Flutter Android App
    ├── lib/
    │   ├── main.dart
    │   ├── screens/        # UI screens
    │   └── services/       # API & Auth services
    ├── android/            # Android configuration
    └── pubspec.yaml
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- Android Studio (for Android SDK)
- MongoDB database
- API keys: OpenAI, Cloudinary, Firebase

### Backend API Setup

1. Navigate to API directory:
```bash
cd api
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file from template:
```bash
cp .env.example .env
```

4. Configure environment variables in `.env`:
```
MONGO_URI=mongodb+srv://...
JWT_SECRET=your_secret
OPENAI_API_KEY=sk-...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

5. Add Firebase service account:
   - Download from Firebase Console
   - Save as `firebase-service-account.json`

6. Start the server:
```bash
npm run dev
```

### Mobile App Setup (Flutter)

1. Navigate to mobile directory:
```bash
cd mobile
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Update API URL in `lib/services/auth_service.dart` if needed:
```dart
static const String baseUrl = 'YOUR_API_URL/api';
```

4. Run the app:
```bash
flutter run
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login

### Issues
- `GET /api/issues/categories` - Get issue categories
- `POST /api/issues` - Create new issue (with AI analysis)
- `GET /api/issues/my` - Get user's issues
- `GET /api/issues/:id` - Get single issue detail
- `PATCH /api/issues/:id/status` - Update issue status (Admin)

### AI Features
- `POST /api/ai/analyze-image` - AI image analysis
- `POST /api/ai/enhance-description` - Enhance description
- `POST /api/ai/chat` - Chat with AI assistant

### Profile
- `GET /api/profile` - Get user profile
- `PATCH /api/profile/fcm-token` - Update FCM token

## Issue Categories
- Damaged Roads
- Broken Streetlights
- Water/Sanitation
- School Infrastructure
- Healthcare Facilities
- Security Concerns
- Other

## Security Features
- JWT token authentication
- bcrypt password hashing
- Rate limiting (100 requests/15min)
- MongoDB injection prevention
- Terms & Privacy Policy acceptance
- 256-bit encryption

## License
MIT License
