# 💬 Vibe — Social & Messaging App

A Flutter social media app powered by **Firebase**. Share posts, connect with friends, and chat in real time — all in one place.

---

## ✨ Features

### 🏠 Home Feed
- Live post feed with photos and captions
- Profile picture and username displayed per post
- Real-time updates via Firestore streams

### 👥 Friends
- Search and add friends
- View your friends list
- Start a chat directly from a friend's profile

### 💬 Messaging
- Real-time 1-on-1 chat using Firestore
- Conversation list sorted by latest message
- Timestamp displayed per message
- Start new conversations via floating button

### 📸 Posts
- Upload photos from gallery using image picker
- Add captions to posts
- Posts stored in Firebase Storage + Firestore

### 👤 Account & Profile
- View and manage your profile
- Profile picture upload
- View your own posts

### 🔔 Notifications
- Push notifications via **Firebase Cloud Messaging**
- Local notification support

### 🔐 Authentication
- Email/password login & registration
- Forgot password flow
- Persistent session with shared preferences

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter · Dart |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging · flutter_local_notifications |
| UI | Material Design · Curved Navigation Bar |
| Media | image_picker |
| Utils | intl · shared_preferences |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry · Firebase init
├── firebase_options.dart      # Firebase config
├── loginscreen.dart           # Login page
├── registerscreen.dart        # Registration page
├── forgotpassword_screen.dart # Forgot password
├── dashboardscreen.dart       # Main shell · bottom nav
├── homescreen.dart            # Social feed
├── addfriends.dart            # Friend discovery
├── myfriends.dart             # Friends list
├── FriendListScreen.dart      # Select friend to chat
├── postscreen.dart            # Create a post
├── MyPostScreen.dart          # View your own posts
├── MessageScreen.dart         # Conversations list
├── ChatScreen.dart            # 1-on-1 chat screen
├── profilescreen.dart         # User profile
├── accountscreen.dart         # Account settings
└── Custom_Widget/
    ├── colorfiles.dart        # App color constants
    ├── mycustombutton.dart    # Reusable button
    └── textfield.dart         # Reusable text field
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.4.3`
- A Firebase project with **Authentication**, **Firestore**, **Storage**, and **Cloud Messaging** enabled

### Setup

```bash
# Clone the repository
git clone https://github.com/Aayush-Ramrakhyani/Messaging_App.git
cd Messaging_App

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> Add your own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase console.

---

## 📄 License

This project was built as part of an internship at **TOPS Technology**. All rights reserved.

---

*Built with Flutter & Firebase · Real-time · Cross-platform*
