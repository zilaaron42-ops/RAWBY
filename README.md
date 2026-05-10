# RAWBY

Weekly filmmaking challenge app — Create. Compete. Grow.

## What Is RAWBY?

RAWBY helps filmmakers build a consistent creative habit through weekly challenges. Get prompts, film your project, submit before the deadline, and compete on the leaderboard.

## Tech Stack

**Frontend (Flutter)**
- Flutter + Dart
- Riverpod for state management
- Hive for local persistence
- go_router for navigation
- Firebase Messaging + local notifications
- Dio for HTTP

**Backend (Dart)**
- Shelf HTTP server
- MongoDB Atlas for persistent storage
- JWT authentication
- Docker deployment on Render

## Project Structure

```
RAWBY/
├── lib/                  # Flutter app source
│   ├── constants/        # App constants, colors
│   ├── models/           # Data models
│   ├── providers/        # Riverpod providers
│   ├── screens/          # App screens
│   ├── services/         # API, storage, notifications
│   ├── theme/            # App theme
│   └── widgets/          # Reusable widgets
├── server/               # Dart backend
│   ├── bin/              # Server entry point
│   ├── lib/              # Server logic & handlers
│   ├── Dockerfile        # Docker build
│   └── render.yaml       # Render deployment config
├── android/              # Android platform
├── ios/                  # iOS platform
├── web/                  # Web platform
└── pubspec.yaml          # Flutter dependencies
```

## Getting Started

```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run

# Run the backend locally
cd server
dart pub get
dart run bin/server.dart
```

## Deployment

See [server/README.md](server/README.md) for backend deployment instructions.
