# Vibe — Social & Messaging App

> Share moments. Chat in real time. Stay connected.

Vibe is a full-featured social app where users can post photos, message friends one-on-one, and build their social circle — all backed by Firebase for real-time sync and push notifications.

---

## Features

**Home Feed**
- Scrollable live feed of photo posts from people you follow
- Each post shows the author's profile picture, username, photo, and caption
- Updates in real time via Firestore streams — no refresh needed

**Messaging**
- Real-time 1-on-1 chat with friends
- Conversations list sorted by latest message with timestamps
- Start a new chat from the friend list with one tap

**Friends**
- Search and send friend requests
- View and manage your friends list
- Jump into a chat directly from a friend's profile

**Posts**
- Pick a photo from your gallery and add a caption
- Posts go live instantly on the feed
- View all your own posts from your profile

**Profile & Account**
- Upload and update your profile picture
- Manage your account details
- View your post history

**Notifications**
- Push notifications via Firebase Cloud Messaging
- Get notified for new messages even when the app is closed

**Authentication**
- Email & password sign up / login
- Forgot password via email reset
- Session persisted across app restarts

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter · Dart |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging · flutter_local_notifications |
| UI | Material Design · Curved Navigation Bar |
| Media | image_picker |
| Utilities | intl · shared_preferences |

---

## Getting Started

**Prerequisites**
- Flutter SDK `>=3.4.3`
- Firebase project with Auth, Firestore, Storage, and Cloud Messaging enabled

**Run locally**

```bash
git clone https://github.com/Aayush-Ramrakhyani/Messaging_App.git
cd Messaging_App
flutter pub get
flutter run
```

> Replace `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) with your own Firebase config files.

---

## 📄 License

This project was built as part of an internship at **TOPS Technology**. All rights reserved.
