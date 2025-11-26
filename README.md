# 📸 AI Photo Studio

Transform your photos with AI-powered scene generation. Upload a photo and watch as AI places you in stunning locations around the world!

Features:
-AI-Powered Transformations - Generate professional photos in different scenes
-Scenes Options - Beach sunsets, city nights, mountain peaks, cozy cafes
-Custom Prompts - Describe your own scene for unique results
-Easy Download - Save generated images to your gallery
-Cross-Platform - Works on Android and iOS

Before running this project, make sure you have:

- Flutter SDK 3.10.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Android Studio / Xcode (for mobile development)
- Firebase account ([Create account](https://firebase.google.com/))
- NanoBanana API key ([Get API key](https://nanobananaapi.ai/))

Installation:

1. Clone the repository
   ```bash
   git clone https://github.com/YOUR_USERNAME/photo_ai_app.git
   cd photo_ai_app
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Firebase Setup
   
   a. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   
   b. Enable these Firebase services:
      - Authentication (Email/Password & Google Sign-In)
      - Cloud Firestore
      - Cloud Storage
      - Cloud Functions
   
   c. Download configuration files:
      - **Android**: Download `google-services.json` → Place in `android/app/`
      - **iOS**: Download `GoogleService-Info.plist` → Place in `ios/Runner/`
   
   d. Add your Firebase config to the app

4. Deploy Cloud Functions
   
   ```bash
   # Navigate to functions directory
   cd functions
   
   # Install dependencies
   npm install
   
   # Login to Firebase
   firebase login
   
   # Set your Firebase project
   firebase use --add
   
   # Set NanoBanana API key as secret
   firebase functions:secrets:set NANOBANANA_API_KEY
   # Enter your API key when prompted
   
   # Deploy functions
   firebase deploy --only functions
   
   # Return to project root
   cd ..
   ```

5. Configure iOS (if building for iOS)
   
   Update `ios/Runner/Info.plist` with required permissions:
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>We need access to your photo library to save images</string>
   
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to take photos</string>
   
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>We need access to save photos to your gallery</string>
   ```

Running the App On Android:
```bash
# Connect your Android device or start emulator
flutter devices

# Run the app
flutter run
```

On iOS (Mac only)
```bash
# Open iOS project
open ios/Runner.xcworkspace

# In Xcode, select your team for code signing
# Then run:
flutter run
```

#### On Web
```bash
flutter run -d chrome
```

## 📱 Building for Production

### Android APK
```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

iOS (requires Mac)
```bash
flutter build ios --release
```

Tech Stack:

- Frontend: Flutter 3.38.2, Dart 3.10.0
- Backend: Firebase (Auth, Firestore, Storage, Functions)
- AI API: NanoBanana API
- State Management: Provider
- Image Handling: image_picker, gal, dio

## 📦 Key Dependencies

```yaml
firebase_core: ^3.6.0          # Firebase initialization
firebase_auth: ^5.3.1          # User authentication
cloud_firestore: ^5.4.4        # Database
firebase_storage: ^12.3.4      # Image storage
cloud_functions: ^5.1.3        # Backend functions
image_picker: ^1.0.7           # Pick images
permission_handler: ^11.1.0    # Handle permissions
gal: ^2.3.0                    # Save to gallery
provider: ^6.1.1               # State management
```

## 🏗️ Project Structure

```
photo_ai_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/
│   │   └── home_screen.dart      # Main screen
│   ├── widgets/
│   │   ├── results_section.dart  # Results display
│   │   ├── controls_section.dart # Controls UI
│   │   └── app_header.dart       # Header widget
│   ├── services/
│   │   └── firebase_service.dart # Firebase integration
│   └── utils/
│       └── constants.dart        # App constants
├── functions/
│   └── index.js                  # Cloud Functions
├── android/                      # Android config
├── ios/                          # iOS config
└── pubspec.yaml                  # Dependencies
```

## 🔧 Configuration

### NanoBanana API

The app uses NanoBanana API for AI image generation. Features:
- Text-to-image generation
- Image-to-image transformation
- Multiple scene templates
- Custom prompt support

Get your API key at [NanoBanana API](https://nanobananaapi.ai/)

### Firebase Functions

Located in `functions/index.js`:
- `generateImages`: Handles AI image generation
- Supports 3 modes:
  - Text-only (custom prompts)
  - Image-only (preset scenes)
  - Text + Image (custom scenes with your photo)

## 🎨 Available Scenes

1. **Tropical Beach** - Sunset with palm trees and turquoise water
2. **City Night** - Modern skyscrapers with bright lights
3. **Mountain Peak** - Sunrise with dramatic clouds
4. **Cozy Cafe** - Aesthetic cafe with warm lighting

## 🐛 Troubleshooting

### Android Issues

**Build fails:**
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**Permission denied:**
- Enable Storage permission in Android settings

### iOS Issues

**CocoaPods error:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

**Code signing error:**
- Open `ios/Runner.xcworkspace` in Xcode
- Select your development team

### Firebase Issues

**Authentication error:**
- Check Firebase console for enabled auth methods
- Verify `google-services.json` / `GoogleService-Info.plist` are in correct locations

**Functions timeout:**
- Image generation can take 2-5 minutes
- Check Firebase Console → Functions → Logs for errors

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

If you have any questions or issues, please open an issue on GitHub.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [NanoBanana API](https://nanobananaapi.ai/) - AI image generation

---

Made with ❤️ using Flutter