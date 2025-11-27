## Spell Daily — Lite

Minimal, production-ready Flutter app that:
- Uses **GetX** for state, routing, and DI.
- Uses **Cloud Firestore** (no Auth) with `users/{loginCode}` documents.
- Launches the daily game in an **in-app WebView**.
- Tracks streaks + today status and exposes data to home screen widgets.

This README covers:
- Firebase setup
- Flutter plugin installation
- Firestore schema + sample data
- Widget update flow (Android & iOS)
- How to run and test

---

### 1. Firebase setup (Android)

1. In the [Firebase console](https://console.firebase.google.com/) create a project.
2. Add an **Android app** with:
   - Package name: `com.spelldaily.spell_daily` (matches `android/app/build.gradle.kts`).
3. Download `google-services.json` and place it at:
   - `android/app/google-services.json` (already done per your note).
4. In **Project settings → General → Your apps → Android**, enable **Firestore**.
5. In the Firebase side menu, go to **Firestore Database → Create database**:
   - Start in **test mode** for development (we’ll harden rules later).

Gradle configuration is already wired:
- Project-level `android/build.gradle.kts`:
  - `id("com.google.gms.google-services") version "4.4.4" apply false`
- App-level `android/app/build.gradle.kts`:
  - `id("com.google.gms.google-services")` in `plugins { … }`
  - Firebase BoM + Firestore/Analytics in `dependencies { … }`

To verify:
```bash
flutter pub get
cd android
./gradlew :app:assembleDebug
```
If this succeeds, the Google services plugin and `google-services.json` are wired correctly.

---

### 2. Flutter plugins (pubspec)

Key dependencies already declared in `pubspec.yaml`:
- **GetX + GetStorage**
  - `get`
  - `get_storage`
- **Firebase**
  - `firebase_core`
  - `cloud_firestore`
- **WebView**
  - `webview_flutter`
- **Widgets & background**
  - `home_widget`
  - `workmanager`
  - `background_fetch`
- **Visual system**
  - `google_fonts`
  - `intl`

Install:
```bash
flutter pub get
```

---

### 3. Firestore schema & sample data

**Collection:** `users`  
**Document ID:** `<loginCode>` (e.g. `ARU123`)

Document shape:
```json
{
  "loginCode": "ARU123",
  "userId": "ARU123",
  "streak": 3,
  "lastCompletedDate": "2025-11-17",
  "todayStatus": "pending", // or "completed"
  "createdAt": 1690000000000,
  "updatedAt": 1690000000000
}
```

There is a ready-made `sample_data.json` at the root of the repo with two users:
- `ARU123` (completed today, streak 3)
- `TES132` (pending, streak 0)

To import sample data:
- Option A: Manually create documents in the Firebase Console under `users`.
- Option B: Use the Firestore REST API or a one-off script to write those two docs.

---

### 4. App architecture overview

Key files:
- `lib/main.dart`
  - Initializes `Firebase.initializeApp()` and `GetStorage.init()`.
  - Registers `AppBindings` and starts `GetMaterialApp`.
- `lib/app_bindings.dart`
  - Registers:
    - `FirebaseFirestore.instance`
    - `GetStorage`
    - `FirestoreService`
    - `WidgetUpdateService` (and calls `.init()`)
    - Controllers: `AuthController`, `StreakController`, `GameController`
- `lib/routes/app_routes.dart` / `app_pages.dart`
  - Defines named routes: splash, entry, login, start, game, result.
- `lib/controllers`
  - `AuthController`
    - `loginWithCode(String code)` → creates/fetches `users/{code}` and persists code in `GetStorage`.
  - `GameController`
    - `startGame()` → navigates to in-app WebView (`/game`) which loads `https://app.spelldaily.com/?code={loginCode}`.
    - `onWebViewClosed()` → re-checks Firestore and routes to Result.
  - `StreakController`
    - `subscribeToFirestore()` + `checkTodayStatus()` + `updateStreakIfCompleted()`.
- `lib/services`
  - `FirestoreService` – wraps `cloud_firestore` document access.
  - `WidgetUpdateService` – coordinates WorkManager + BackgroundFetch + home_widget.
- `lib/screens`
  - Splash, Entry Gate, Login, Start Game, Game (WebView), Result.
- `lib/widgets`
  - `StreakWidget` and `StreakPopup`.
- `lib/utils`
  - `app_colors.dart`, `app_text_styles.dart`.

---

### 5. Widget update flow (Android & iOS)

#### Android

- Uses:
  - `workmanager` to schedule a one-off job ~10 minutes after completion.
  - `home_widget` to update the homescreen widget UI.
- Native side:
  - There is an existing `StreakWidgetProvider.kt` in `android/app/src/main/kotlin/...`.
  - The `WidgetUpdateService` calls:
    - `Workmanager().initialize(_callbackDispatcher, …)`
    - `HomeWidget.updateWidget(name: 'StreakWidgetProvider')` inside the background callback.

High-level logic:
1. Web game sets Firestore: `todayStatus = "completed"` and `lastCompletedDate = "YYYY-MM-DD"`.
2. `StreakController` picks this up via its Firestore listener and updates reactive state.
3. `GameController.onWebViewClosed()`:
   - Confirms completion (`checkTodayStatus()`).
   - Calls `updateStreakIfCompleted()` to bump streak.
   - Calls `WidgetUpdateService.scheduleDelayedRefresh(Duration(minutes: 10))`.
4. WorkManager job runs, re-checks state and calls `HomeWidget.updateWidget()` so the native widget shows “Game Completed”.

To test on Android:
1. Run the app on a physical/emulator device.
2. Long press the launcher icon → add the Spell Daily widget (depending on manufacturer).
3. Log in with a sample code and complete the simulated game.
4. Confirm the widget updates to state 3 (completed) after the configured delay.

#### iOS

- Approach:
  - Use `home_widget` + WidgetKit (SwiftUI extension target).
  - Use `background_fetch` for periodic background refreshes (subject to iOS limitations).
- Steps (high level, some manual Xcode work required):
  1. In Xcode, add a Widget Extension (WidgetKit) target.
  2. Use `home_widget` to share data between Flutter and the widget (`HomeWidget.saveWidgetData`).
  3. Configure `background_fetch` in `AppDelegate` to trigger periodic fetches that:
     - Hit Firestore (or a cached snapshot).
     - Save the latest streak data to shared storage.
     - Call `HomeWidget.updateWidget()` to refresh the WidgetKit timeline.

Fallback behavior:
- If the platform does not support programmatic widget updates or background tasks are throttled, the widget will show the last-known state until the user opens the app again.

---

### 6. Running & testing the app

Run:
```bash
flutter run
```

Flow to test:
1. **Splash → Entry Gate → Login**
   - Enter a code (e.g. `ARU123` or `TES132`).
   - This will create/fetch `users/{code}` and navigate to Start Game.
2. **Start Game**
   - See the streak card and “START GAME” button.
   - Tap it to open the in-app WebView.
3. **Game (WebView)**
   - For real integration: the game at `https://app.spelldaily.com/?code={code}` writes `todayStatus` and `lastCompletedDate` to Firestore.
   - For dev: update the document manually in the Firebase console to simulate completion.
4. Close the WebView (back/close button).
   - `onWebViewClosed()` re-checks Firestore and routes to Result.
5. **Result**
   - Success → shows “Nice work!” and increments streak.
   - Failure → shows “Not yet completed” and a “Try Again” button.

Tests:
- There is a lightweight integration-style test file:
  - `test/integration_spell_daily_test.dart`
  - Uses in-memory stand-ins to show:
    - Login creating a new user doc.
    - Updating `todayStatus` to `"completed"` and having a streak controller detect it.

Run tests:
```bash
flutter test
```

---

### 7. Firestore security rules (dev vs production)

**Development (open prototype)** – easiest for now:
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{loginCode} {
      allow read, write: if true;
    }
  }
}
```

**Prototype with public writes for `users` only:**
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{loginCode} {
      allow read, write: if request.resource.data.loginCode == loginCode;
    }
  }
}
```

**Production-ready idea (future Auth phase):**
- Introduce Firebase Auth and make:
  - `users/{loginCode}` store a `uid` field.
  - Rules:
    ```js
    allow read, write: if request.auth != null &&
      request.auth.uid == resource.data.uid;
    ```

---

### 8. Figma file guidance (since we can’t attach .fig here)

Create a Figma file named **“Spell Daily — Lite”** with:

- **Frames (360×800 mobile):**
  - Splash
  - Entry Gate
  - Login
  - Start Game
  - Game (WebView mock)
  - Result
  - Components page (StreakWidget, StreakPopup, PrimaryButton, CodeInput, StreakCard, WeeklyProgressBadge)
- **Colors:**
  - Primary Purple: `#5103D5`
  - Orange: `#FFB638`
  - White: `#FFFFFF`
  - Text Light Purple: `#D8C7FA`
  - Dark Purple: `#3A007F`
- **Typography (Roboto):**
  - Headings: Roboto 700/900
  - Buttons: 900, letter-spacing 1.5–3
  - Code input: uppercase, letter-spacing 5
- **Text styles named to match Flutter:**
  - `AppTextStyles.logoStyle`
  - `AppTextStyles.buttonStyle`
  - `AppTextStyles.body`
  - `AppTextStyles.codeInput`
- **Components:**
  - `PrimaryButton` (default, disabled, loading)
  - `CodeInput` (idle, focused, error)
  - `StreakCard` with variants for states 1–4 (pending, inProgress, completed, reminder)
  - `WeeklyProgressBadge` with tick glyphs
  - `StreakPopup` (modal overlay)

Publish the file and share the link with your team; they can inspect spacing and re-use the tokens directly in Flutter.

---

### 9. Platform caveats (widgets/background)

- **Android**
  - WorkManager typically runs, but exact timing isn’t guaranteed (device/OS dependent).
  - Some OEMs may aggressively kill background tasks; the widget will still update when the app is opened.
- **iOS**
  - `background_fetch` is opportunistic; you can’t rely on exact 10-minute timing.
  - WidgetKit timelines also have OS-driven refresh policies.
- Recommendation:
  - Treat the 10-minute update as **best-effort UX**, not a strict SLA.
  - Always keep the in-app UI authoritative; the widget is a convenience surface.




