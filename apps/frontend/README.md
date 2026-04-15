# Frontend

Flutter client for the Spiritual Q&A Platform.

## Local development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Create `apps/frontend/.env` before running locally. The minimum required value is:

```env
API_BASE_URL=http://localhost:8000
```

## Verification

```bash
flutter analyze
flutter test --coverage
flutter build web --release
```
