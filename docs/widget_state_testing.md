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

