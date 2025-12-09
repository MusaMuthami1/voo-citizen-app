# Native Mobile App - React Native + Python Implementation Plan

## Goal Description

Create a **native mobile application** for Kyamatu Ward citizens using:
- **Frontend**: React Native (cross-platform iOS & Android)
- **Backend**: Python FastAPI (replacing Node.js)

This will provide a true native app experience with better performance, native features, and app store distribution.

---

## User Review Required

> [!IMPORTANT]
> **Technology Stack Change**
> - Replacing web PWA with React Native mobile app
> - Replacing Node.js backend with Python FastAPI
> - Existing Node.js USSD service will remain for USSD functionality
> - New Python backend will handle mobile app API only

> [!WARNING]
> **New Requirements**
> - Android Studio (for Android development)
> - Xcode (for iOS development - Mac only)
> - Python 3.10+ installed
> - Expo CLI for React Native development
> - PostgreSQL database (can reuse existing)

> [!CAUTION]
> **Development Time**
> - React Native app: 1-2 weeks
> - Python backend: 3-5 days
> - Testing & deployment: 3-5 days
> - **Total**: 2-3 weeks for production-ready app

---

## Proposed Changes

### Phase 1: Python FastAPI Backend

#### [NEW] [mobile-backend/](file:///c:/Users/Admin/USSD/mobile-backend/)
New Python backend specifically for mobile app

#### [NEW] [mobile-backend/main.py](file:///c:/Users/Admin/USSD/mobile-backend/main.py)
- FastAPI application setup
- CORS configuration for mobile app
- Database connection with SQLAlchemy
- JWT authentication middleware

#### [NEW] [mobile-backend/models/](file:///c:/Users/Admin/USSD/mobile-backend/models/)
- `citizen.py` - Citizen user model
- `issue.py` - Issue model with photo URLs
- `bursary.py` - Bursary application model
- `otp.py` - OTP verification model

#### [NEW] [mobile-backend/routes/](file:///c:/Users/Admin/USSD/mobile-backend/routes/)
- `auth.py` - OTP request/verify, JWT token generation
- `issues.py` - CRUD operations for issues
- `bursaries.py` - Bursary status endpoints
- `upload.py` - Photo upload to Cloudinary/S3

#### [NEW] [mobile-backend/services/](file:///c:/Users/Admin/USSD/mobile-backend/services/)
- `sms_service.py` - Send OTP via Africa's Talking
- `notification_service.py` - Push notifications via Firebase
- `ai_service.py` - OpenAI integration for categorization
- `storage_service.py` - Photo storage (Cloudinary)

#### [NEW] [mobile-backend/requirements.txt](file:///c:/Users/Admin/USSD/mobile-backend/requirements.txt)
```txt
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
cloudinary==1.36.0
openai==1.3.0
africastalking==1.2.6
firebase-admin==6.3.0
pydantic==2.5.0
python-dotenv==1.0.0
```

---

### Phase 2: React Native Mobile App

#### [NEW] [mobile-app/](file:///c:/Users/Admin/USSD/mobile-app/)
React Native application with Expo

#### [NEW] [mobile-app/App.js](file:///c:/Users/Admin/USSD/mobile-app/App.js)
- Main app component
- Navigation setup (React Navigation)
- Authentication context provider
- Theme configuration

#### [NEW] [mobile-app/src/screens/](file:///c:/Users/Admin/USSD/mobile-app/src/screens/)
- `LoginScreen.js` - OTP authentication
- `DashboardScreen.js` - Main navigation hub
- `ReportIssueScreen.js` - Issue reporting with camera
- `MyIssuesScreen.js` - Issue tracking list
- `IssueDetailScreen.js` - Individual issue details
- `BursaryStatusScreen.js` - Bursary applications

#### [NEW] [mobile-app/src/components/](file:///c:/Users/Admin/USSD/mobile-app/src/components/)
- `IssueCard.js` - Reusable issue display
- `StatusBadge.js` - Status indicator
- `PhotoPicker.js` - Camera/gallery picker
- `LoadingSpinner.js` - Loading indicator

#### [NEW] [mobile-app/src/services/](file:///c:/Users/Admin/USSD/mobile-app/src/services/)
- `api.js` - Axios API client
- `auth.js` - Authentication helpers
- `storage.js` - AsyncStorage wrapper
- `notifications.js` - Push notification setup

#### [NEW] [mobile-app/app.json](file:///c:/Users/Admin/USSD/mobile-app/app.json)
```json
{
  "expo": {
    "name": "Kyamatu Ward",
    "slug": "kyamatu-ward",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "splash": {
      "image": "./assets/splash.png",
      "backgroundColor": "#7c3aed"
    },
    "android": {
      "package": "com.kyamatuward.citizen",
      "permissions": ["CAMERA", "READ_EXTERNAL_STORAGE"]
    },
    "ios": {
      "bundleIdentifier": "com.kyamatuward.citizen",
      "supportsTablet": true
    }
  }
}
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│         React Native Mobile App            │
│  (iOS & Android - Expo/React Native)       │
│                                             │
│  Screens:                                   │
│  - Login (OTP)                              │
│  - Dashboard                                │
│  - Report Issue (Camera)                    │
│  - My Issues                                │
│  - Bursary Status                           │
└──────────────┬──────────────────────────────┘
               │ REST API (HTTPS)
               │
┌──────────────▼──────────────────────────────┐
│       Python FastAPI Backend               │
│         (Port 8000)                         │
│                                             │
│  Endpoints:                                 │
│  - POST /api/auth/request-otp               │
│  - POST /api/auth/verify-otp                │
│  - GET  /api/issues                         │
│  - POST /api/issues (with photo)            │
│  - GET  /api/bursaries                      │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│         PostgreSQL Database                 │
│  (Shared with existing USSD system)         │
│                                             │
│  Tables:                                    │
│  - citizens                                 │
│  - issues                                   │
│  - bursaries                                │
│  - otp_codes                                │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│      External Services                      │
│                                             │
│  - Cloudinary (Photo Storage)               │
│  - Africa's Talking (SMS OTP)               │
│  - Firebase (Push Notifications)            │
│  - OpenAI (AI Categorization)               │
└─────────────────────────────────────────────┘
```

---

## Verification Plan

### Backend Testing
```bash
# Install dependencies
cd mobile-backend
pip install -r requirements.txt

# Run FastAPI server
uvicorn main:app --reload --port 8000

# Test endpoints
curl http://localhost:8000/docs  # Swagger UI
```

### Mobile App Testing
```bash
# Install Expo CLI
npm install -g expo-cli

# Create and run app
cd mobile-app
npm install
expo start

# Test on:
# - Android: Scan QR with Expo Go app
# - iOS: Scan QR with Camera app
# - Emulator: Press 'a' for Android, 'i' for iOS
```

### Integration Testing
1. Request OTP from mobile app
2. Verify OTP received via SMS
3. Login and get JWT token
4. Report issue with photo
5. View issue in list
6. Check bursary status

---

## Deployment Strategy

### Python Backend
**Option 1: Railway.app** (Recommended)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
cd mobile-backend
railway login
railway init
railway up
```

**Option 2: Render.com**
- Connect GitHub repo
- Select `mobile-backend` folder
- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Mobile App
**Android:**
```bash
cd mobile-app
expo build:android
# Download APK and upload to Google Play Store
```

**iOS:**
```bash
cd mobile-app
expo build:ios
# Download IPA and upload to App Store Connect
```

---

## Environment Variables

### Python Backend (.env)
```bash
DATABASE_URL=postgresql://user:pass@host:5432/dbname
JWT_SECRET=your-secret-key
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
AFRICASTALKING_USERNAME=sandbox
AFRICASTALKING_API_KEY=your-api-key
OPENAI_API_KEY=sk-xxxxx
FIREBASE_CREDENTIALS=path/to/firebase-credentials.json
```

### React Native App (.env)
```bash
API_URL=https://your-backend.railway.app
FIREBASE_API_KEY=your-firebase-key
```

---

## Cost Estimates

| Service | Monthly Cost |
|---------|-------------|
| Railway (Python backend) | $5-10 |
| Cloudinary (Photo storage) | Free tier (25GB) |
| Africa's Talking (SMS) | ~$10 |
| Firebase (Push notifications) | Free tier |
| OpenAI API | ~$20 |
| **Total** | **$35-40/month** |

**App Store Fees:**
- Google Play: $25 one-time
- Apple App Store: $99/year

---

## Timeline

### Week 1: Backend Development
- Day 1-2: FastAPI setup, database models
- Day 3-4: Authentication & API endpoints
- Day 5: Photo upload & integrations

### Week 2: Mobile App Development
- Day 1-2: React Native setup, navigation
- Day 3-4: Screens & components
- Day 5: Camera, offline support

### Week 3: Testing & Deployment
- Day 1-2: Integration testing
- Day 3-4: Bug fixes, polish
- Day 5: Deploy backend & build apps

---

## Success Metrics

- ✅ App loads in <2 seconds
- ✅ Photo upload works on both platforms
- ✅ Offline mode caches data
- ✅ Push notifications delivered
- ✅ OTP received within 30 seconds
- ✅ 4.5+ star rating target

---

## Next Steps

1. **Choose approach:**
   - Option A: Build from scratch (full control)
   - Option B: Use Expo managed workflow (faster)

2. **Set up development environment:**
   - Install Python 3.10+
   - Install Node.js & Expo CLI
   - Install Android Studio / Xcode

3. **Start with backend:**
   - Create FastAPI project
   - Set up database models
   - Build authentication

4. **Then build mobile app:**
   - Initialize React Native project
   - Create screens
   - Integrate with backend

**Ready to start? Which option do you prefer?**
