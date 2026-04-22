# pre_order_system

Campus canteen pre-order Flutter app with Firebase Authentication and Cloud Firestore real-time order tracking.

## Firebase Setup

1. Create a Firebase project in Firebase Console.
2. Enable Authentication -> Sign-in method -> Email/Password.
3. Create Firestore Database in production mode.
4. Register Android/iOS/Web apps in Firebase.
5. Add platform config files:
	- Android: `android/app/google-services.json` exactly
	- iOS/macOS: `ios/Runner/GoogleService-Info.plist` and `macos/Runner/GoogleService-Info.plist`
	- Web: configure via FlutterFire CLI and generated options
6. Run:

```bash
flutter pub get
flutter run
```

## Firestore Collections

### users
- Document id: Firebase UID
- Fields: `name`, `email`, `role`

### orders
- Auto document id
- Fields: `token`, `userId`, `userName`, `items`, `totalAmount`, `createdAt`, `status`, `estimatedMinutes`

## Real-time Behavior

- Admin and user order screens are powered by Firestore snapshot streams.
- Order status updates are persisted in Firestore and reflected live across screens.
- Current serving token is derived from latest ready order.

## Evaluation Checklist Mapping

### Implemented now
- Firebase Auth (email/password) integrated.
- Firestore-backed orders with real-time stream updates.
- Business logic kept in services (`mock_auth_service.dart`, `order_service.dart`) and out of widget build trees.

### Still recommended before final production evaluation
- Single explicit state management framework (Bloc or Riverpod) across entire app.
- Dependency injection container (`get_it`/Provider) for service registration.
- `flutter_secure_storage` for sensitive data handling.
- Crash reporting with Firebase Crashlytics.
- Test suite expansion (unit/widget/golden) to target >70% business-logic coverage.
- Release hardening: `--obfuscate --split-debug-info` and environment secret strategy (`--dart-define`/`.env`).
