# Vibe — Social & Messaging App

> Share moments. Chat in real time. Stay connected.

Vibe is a full-featured social app where users can post photos, message friends one-on-one, chat in groups, and build their social circle — all backed by Firebase for real-time sync and push notifications.

Built for TOPS Technology as part of an internship contract (Apr 2024).

---

## Features

**Home Feed**
- Scrollable live feed of photo posts from people you follow
- Each post shows the author's profile picture, username, photo, and caption
- Like posts with a heart animation; view and add comments
- Updates in real time via Firestore streams — no refresh needed

**Direct Messaging**
- Real-time 1-on-1 chat with friends
- Send text messages and photos
- Typing indicator with 3-second debounce
- Conversations list sorted by latest message with online status dots
- Date separators (Today / Yesterday / date) inside chat

**Group Chat**
- Create a group with any number of friends
- Sequential message grouping — consecutive messages from the same sender collapse the avatar and name label, showing them only at the start and end of each run
- Each sender gets a consistent color label for easy identification
- Send text and images; inbox shows last message preview and member count
- Group metadata (name, members, last activity) stored in Firestore with subcollection messages for clean security scoping

**Friends**
- Search and send friend requests
- View and manage incoming requests
- Jump into a chat directly from the friend picker

**Posts**
- Pick a photo from your gallery and add a caption
- Posts go live instantly on the feed
- Edit or delete your own posts from your profile
- Comment on posts with a live comment count badge

**Profile & Account**
- Upload and update your profile picture
- Manage your account details
- Toggle dark / light mode (persisted across restarts)
- View your post history

**Notifications**
- Push notifications via Firebase Cloud Messaging
- Get notified for new messages even when the app is closed

**Authentication**
- Email & password sign up / login
- Forgot password via email reset
- Session persisted across app restarts
- Auth rollback — Firebase Auth user is deleted if Firestore profile write fails during registration

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x · Dart 3.x |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging · flutter_local_notifications |
| UI | Material 3 · google_fonts (Poppins) · curved_navigation_bar |
| Animations | flutter_animate · Hero transitions |
| Media | image_picker |
| Utilities | intl · shared_preferences |

---

## Project Structure

```
lib/
├── main.dart                     # App entry, theme notifier
├── splashscreen.dart             # Animated splash with auth check
├── loginscreen.dart              # Email/password login
├── registerscreen.dart           # Sign up with avatar picker
├── forgotpassword_screen.dart    # Password reset
├── dashboardscreen.dart          # Shell with bottom nav (PageView)
├── homescreen.dart               # Social feed with likes & comments
├── postscreen.dart               # Create / edit a post
├── MyPostScreen.dart             # Your own post history
├── commentsscreen.dart           # Comments on a post
├── profilescreen.dart            # Edit profile
├── accountscreen.dart            # Settings & dark mode toggle
├── addfriends.dart               # Discover & add people
├── myfriends.dart                # Incoming friend requests
├── MessageScreen.dart            # DM inbox + group chats entry
├── ChatScreen.dart               # 1-to-1 real-time chat
├── FriendListScreen.dart         # Friend picker to start a DM
├── GroupListScreen.dart          # Group chat inbox
├── GroupChatScreen.dart          # Group chat with sequential grouping
├── CreateGroupScreen.dart        # Create a new group
└── Custom_Widget/
    ├── app_colors.dart           # Central palette & gradients
    ├── app_theme.dart            # Material 3 light/dark themes
    ├── app_routes.dart           # SlidePageRoute / FadePageRoute
    ├── mycustombutton.dart       # GradientButton widget
    └── textfield.dart            # AppTextField widget
```

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

**Required Firestore indexes**

The group chat inbox query needs a composite index:

| Collection | Field 1 | Field 2 |
|------------|---------|---------|
| `groups` | `members` (Array) | `lastMessageTime` (Descending) |

Firestore will show a direct link to create it the first time `GroupListScreen` loads.

---

## License

This project was built as part of an internship at **TOPS Technology**. All rights reserved.
