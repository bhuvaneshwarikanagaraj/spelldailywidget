## Widget State Testing Guide

Widgets can now live entirely on their own: each instance stores a JSON payload through the `home_widget` plugin, while Firestore (`widgetStates` collection) remains the source of truth for multi-device sync. Every widget supports **five** UI states that match the latest PNG mocks:

| State | Code | Description | UI cue |
|-------|------|-------------|--------|
| 0 | `unlinked` | Widget not paired with a login code | Purple card + “Link your widget” |
| 1 | `state1` | Linked, ready to start | Logo + BEGIN button showing CODE |
| 2 | `state2` | User just tapped BEGIN | “Did you just do that?!” celebration |
| 3 | `state3` | Same-day lock screen | Week progress row, no button |
| 4 | `state4` | Waiting for today’s play | Week row + yellow “Start Game” button |

When BEGIN is tapped, the widget immediately switches to **state2**, schedules a 10-minute job (state2 → state3) and a midnight job (state3 → state4) via `WorkManager`. No app relaunch is required.

---

### 1. Firestore collection schema

- **Collection:** `widgetStates`
- **Document ID:** uppercase login code
- **Fields:**
  - `loginCode` *(string)*
  - `state` *(string)* – one of `unlinked`, `state1`, `state2`, `state3`, `state4`
  - `streakCount` *(number)*
  - `weekProgress` *(array<bool> length 7)*
  - `manualOverride` *(bool)* – set to `true` when QA forces a value
  - `lastPlayedDate` *(string, optional)*
  - `lastUpdated` *(timestamp via `FieldValue.serverTimestamp()` )*

See `sample_widget_states.json` for ready-to-import payloads.

---

### 2. Seed/reset the sample doc (`ABC123`)

```sh
firebase firestore:documents:set widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    loginCode:"ABC123",
    state:"state1",
    streakCount:0,
    weekProgress:[false,false,false,false,false,false,false],
    manualOverride:false,
    lastPlayedDate:"2025-11-27",
    lastUpdated:="__name__"
  }'
```

---

### 3. Quick commands to flip between states

```sh
# state0 – Unlinked
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"unlinked",
    streakCount:0,
    weekProgress:[false,false,false,false,false,false,false],
    manualOverride:true
  }'

# state1 – Start challenge
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state1",
    streakCount:0,
    weekProgress:[false,false,false,false,false,false,false],
    manualOverride:true
  }'

# state2 – Just completed
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state2",
    streakCount:3,
    weekProgress:[true,true,true,false,false,false,false],
    manualOverride:true
  }'

# state3 – Completed today
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state3",
    streakCount:7,
    weekProgress:[true,true,true,true,true,true,false],
    manualOverride:true
  }'

# state4 – Awaiting today
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state4",
    streakCount:10,
    weekProgress:[true,true,true,true,true,true,true],
    manualOverride:true
  }'
```

Setting `manualOverride:true` ensures the mobile app will not overwrite your manual test values until you reset it.

---

### 4. Pairing widgets with login codes

1. Drop the widget on the Android home screen (shows state0).
2. Tap it; the app opens Login with “Linking home-screen widget #<id>”.
3. Enter the login code (e.g. `ABC123`) → **Link Widget**. The widget stores the assignment (`widget_assignment_<id>`) and switches to state1.
4. Repeat for additional widgets. Each widget ID is isolated even if codes repeat.

After linking:

- Tapping BEGIN opens the browser, sets the widget to state2, and schedules the background transitions.
- ~10 minutes later, state3 appears automatically.
- After midnight, the widget becomes state4 and the yellow START GAME button returns.

---

### 5. Widget Admin screen (in-app QA console)

1. Open **Start Game** → tap **Widget Admin**.
2. Each row shows widget ID, login code, streak count, week flags, and state chip.
3. Buttons `State 1`–`State 4` call `WidgetStateService.overrideState()` which:
   - sets `manualOverride:true` in Firestore,
   - persists the new payload via `WidgetBridge`,
   - triggers `HomeWidget.updateWidget(name: 'StreakWidgetProvider')`, and
   - updates only that widget’s RemoteViews.
4. Use **Unlink** to clear the assignment (drops to state0) or the refresh icon if you changed Firestore manually.

This screen is the recommended way to verify all five PNG-aligned layouts without juggling Firestore.

---

### 6. Forcing a background refresh

Widgets refresh when:

- Firestore listeners stream new data while the app is foregrounded.
- `BackgroundFetch` wakes the headless Dart isolate (every ~15 minutes).
- The app launches (`WidgetStateService.bootstrap()` re-syncs everything).

Manual trigger:

```sh
adb shell cmd jobscheduler run -f com.company.spelldaily 999
```

This runs `widgetBackgroundFetch`, which calls `WidgetStateService.syncAllFromFirestore()` and `HomeWidget.updateWidget()` so the latest payload is rendered immediately.

---

### 7. Troubleshooting checklist

- **Widget still says LINK:** ensure the widget ID is linked (Widget Admin shows the assignment) and the Firestore doc isn’t `state:"unlinked"`.
- **Manual overrides not visible:** confirm `manualOverride:true`, hit refresh on Widget Admin, and confirm the login code matches exactly (case-sensitive).
- **Timed transitions missing:** run `adb shell dumpsys jobscheduler | findstr widget_` to see pending jobs, or tap BEGIN again to reschedule. You can also trigger the workers inside Android Studio.
- **Multiple widgets show identical data unexpectedly:** verify each widget ID in Widget Admin—link/unlink individually as needed. It’s valid to reuse a login code intentionally; those widgets will stay in sync by design.

Use `sample_widget_states.json` for additional payload examples or clone it to seed more QA codes.
## Widget State Testing Guide

This project now supports pairing multiple home‑screen widgets with different login codes so you can monitor several streaks side‑by‑side. The `widgetStates` Firestore collection is the single source of truth for every widget instance. Updating a document in this collection (either manually in the Firebase Console or through the CLI) will push the new state to any widget that is linked to the corresponding `loginCode`. Background fetch runs every ~15 minutes (and also when the app is foregrounded) to keep widgets fresh even if the app is not running.

---

### 1. Firestore collection schema

- **Collection:** `widgetStates`
- **Document ID:** the exact login code used in the app/widget (store in uppercase for consistency).
- **Fields:**
  - `loginCode` *(string)* – redundant guard; must match the document id.
  - `state` *(string)* – one of `state1`, `state2`, `state3`, `state4`.
  - `streakCount` *(number)* – total consecutive days completed.
  - `weekProgress` *(array<bool> length 7)* – Monday → Sunday completion flags.
  - `manualOverride` *(bool)* – when `true`, the mobile app will not overwrite this document.
  - `lastPlayedDate` *(string, optional)* – ISO date for audits (not consumed by the widget but useful for QA).
  - `lastUpdated` *(timestamp)* – set to `FieldValue.serverTimestamp()` so you know when the doc was touched.

The same schema is documented in `sample_widget_states.json`, which now ships with a ready‑to‑import document for the sample login code **ABC123** plus presets for each state.

---

### 2. Create / reset the sample doc (`ABC123`)

Using the Firebase CLI (replace `<project-id>` with your project, e.g. `spell-daily-85ef0`):

```sh
firebase firestore:documents:set widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    loginCode:"ABC123",
    state:"state1",
    streakCount:0,
    weekProgress:[false,false,false,false,false,false,false],
    manualOverride:false,
    lastPlayedDate:"2025-11-27",
    lastUpdated:="__name__"
  }'
```

> Tip: If you prefer the Console, copy the payload from `sample_widget_states.json`.

---

### 3. Quick commands to flip between the four states

Once the document exists you only need to update the relevant fields. Below are ready‑to‑paste commands (again replace `<project-id>`). The `weekProgress` arrays are just examples to help you visualize each state; tweak them freely.

```sh
# state1 – Start challenge
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state1",
    streakCount:0,
    weekProgress:[false,false,false,false,false,false,false],
    manualOverride:true
  }'

# state2 – Just completed
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state2",
    streakCount:3,
    weekProgress:[true,true,true,false,false,false,false],
    manualOverride:true
  }'

# state3 – Completed & locked for today
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state3",
    streakCount:7,
    weekProgress:[true,true,true,true,true,true,false],
    manualOverride:true
  }'

# state4 – Awaiting today
firebase firestore:documents:update widgetStates/ABC123 \
  --project <project-id> \
  --data '{
    state:"state4",
    streakCount:10,
    weekProgress:[true,true,true,true,true,true,true],
    manualOverride:true
  }'
```

Setting `manualOverride:true` ensures the mobile app will keep your manual value until you switch it back (the app automatically resets the flag to `false` when it syncs after a local play session).

---

### 4. Pairing widgets with login codes

1. **Drop a widget** on the Android home screen.
2. **Tap the widget**. Because it is unlinked, it will open the app instead of the browser and show a “Link your widget” banner.
3. **Enter the login code** (e.g. `ABC123`) and press **Link Widget**. The widget now stores the assignment and displays `CODE: ABC123`.
4. Repeat for each widget you add—you can link different codes (e.g. `ABC123` and `XYZ789`) and monitor both simultaneously.

> You can still log into the app normally (via the launcher icon). That flow is untouched and continues to control the in‑app experience.

---

### 5. Forcing a background refresh (optional)

Widgets update automatically when:

- the Firestore listener receives a change while the app is running, or
- Android triggers the periodic background fetch (every ~15 minutes), or
- you open the app (bootstrap re-syncs everything).

For QA you can force the background task via `adb`:

```sh
adb shell cmd jobscheduler run -f com.company.spelldaily 999
```

This immediately invokes the headless `widgetBackgroundFetch`, which pulls the latest `widgetStates` docs and pushes them to every paired widget.

---

### 6. Troubleshooting checklist

- Widget still shows “TAP TO LINK”: open the widget (tap it), link the desired login code, and ensure the Firestore doc exists.
- Changes do not appear: confirm `manualOverride` is `true` (to hold manual edits) and that the doc’s `loginCode` matches the widget’s code exactly (case‑sensitive).
- Multiple widgets with the same code: simply link both widgets to the same login code; they will stay in sync automatically.

Refer to `sample_widget_states.json` for more payload examples or duplicate it to seed additional test users.

