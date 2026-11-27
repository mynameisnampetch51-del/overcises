# Overcise app

Flutter demo. All data is fake and held in memory. Demo login:
`demo@overcise.app` / `123456`.

Jumping jacks are counted from the webcam in the **web build** only
(MediaPipe, in `web/mediapipe/`). Sit-ups, and every platform without a pose
model, run in demo mode with simulated reps.

## Run

```bash
flutter run -d chrome --no-web-resources-cdn
```

`--no-web-resources-cdn` serves Flutter's renderer locally instead of from a
CDN. Fonts may still be fetched online.

## Check

```bash
flutter analyze
flutter test
```
