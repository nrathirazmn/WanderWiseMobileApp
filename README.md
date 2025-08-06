# WanderWise - Your Smart Travel Companion

WanderWise is an AI-powered travel companion designed to enhance how users explore, plan, and experience trips. From planning own itineraries to tracking spending and browsing through other forums and guides from users, and chatting with an AI assistant, WanderWise combines intelligence, simplicity, and utility into one seamless app.

---

# Features Overview

WanderWise empowers users to:

- **Chat with an AI travel assistant**
  - Get smart recommendations and personalized travel tips.
- **Use a built-in currency converter and expense tracker**
  - Convert currencies and track trip expenses in one place
- **Explore forum-style travel guides**
  - Browse travel posts, save guides, and interact with tips
- **Plan own itineraries**
  - Create itineraries where it allows for detailed planning including daily breakdowns and budget planner
- **Travel Buddy**
  - Tinder like feature wherein users can meet like-minded users to travel together 
- **Chat Messages**
  - Chat with your travel buddies and the AI travel assistant
- **Profile & personalization**
  - Access saved guides and itineraries from your profile screen


---

## Setup Instructions

1. **Clone the repo:**
   ```bash
   git clone https://github.com/nrathirazmn/WanderWiseMobileApp.git
   cd wanderwise
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Ensure assets are registered (e.g. events.json, icons, fonts):**
   - Check `pubspec.yaml` for proper asset declarations.

---

## Technical Architecture

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **API Integration:** OpenRouter API (for AI Assistant)
- **Data:** Firebase for storing users, events, itineraries, and chats
- **Modular Design:** Code is split into services, components, screens, and widgets

---

## Third-party Packages Used

| Package Name       | Purpose                                                                 |
|--------------------|-------------------------------------------------------------------------|
| `intl`             | For internationalization and date/time formatting.                      |
| `pdf`              | To generate PDF documents for itineraries or travel summaries.          |
| `url_launcher`     | To open URLs (e.g., Google Maps, websites) from the app.                |
| `cupertino_icons`  | Provides iOS-style icons used in the UI.                                |
| `http`             | For making HTTP requests (e.g., fetching external data, APIs).          |
| `firebase_core`    | Required to initialize Firebase in the app.                             |
| `firebase_auth`    | For user authentication via Firebase (email/password or other methods). |
| `cloud_firestore`  | Cloud-hosted NoSQL database to store and retrieve app data.             |
| `firebase_storage` | Used for uploading and retrieving user files and images.                |
| `image_picker`     | Allows users to pick images from their gallery or take new ones.        |
| `uuid`             | For generating unique IDs (e.g., for posts or itineraries).             |
| `confetti`         | Adds visual celebration effects (e.g., when a booking is confirmed).    |
| `lottie`           | To include engaging Lottie animations in onboarding or success screens. |
| `pie_chart`        | Visualize expenses or itinerary data in pie chart format.               |

---

## Build APK for Release

To build an APK for Android:

```bash
flutter build apk --release
```

You can find the generated `.apk` file at:

```
/build/app/outputs/flutter-apk/app-release.apk
```

---

## Known Limitations & Considerations

- **AI Assistant limited to one endpoint:** Additional memory/context handling can be explored later
- **Not supported in offline mode:** Limitation in which user will always need to be connected to internet

---

## Future Enhancements

- Expand AI assistant capabilities (e.g., itinerary generation and user preferences centric)
- Add travel journal feature for trip logs

---
