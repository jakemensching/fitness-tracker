# Overload Lift Log

A personal, mobile-first workout tracker built around progressive overload and body weight. One file (`index.html`), no build step.

## Features

- **Logging**: sessions with exercises and sets (weight in lbs, reps, optional RPE). 38 preloaded lifts plus custom exercises, each tagged with a muscle group. Leg lifts sit under one Legs category with subcategories: Quads, Hamstrings, Adductors, Abductors and Calves.
- **Beat this**: picking an exercise shows last session's sets and the next target. There are also "Copy last session" and "Fill target" buttons.
- **PR badge** shows the moment a set beats your previous best weight or e1RM.
- **Body weight** logging with a 7-day moving average.
- **Edit or delete** any session or weigh-in.
- **Steps from Apple Health**: an iPhone Shortcut sends each day's step count. Steps show on the Log tab and in a Steps section on the Body tab (today, 7-day average of completed days, week-over-week change, daily chart).

### Calculations

- Estimated 1RM per set uses Epley: `weight × (1 + reps / 30)`. The best set is the session's e1RM.
- Session volume is the sum of `weight × reps`.
- Bodyweight lifts (pull-ups, chin-ups, dips, hanging leg raise) count body weight plus added weight. Body weight is the 7-day average on that date.
- Relative strength is best e1RM ÷ current 7-day body weight average.
- Next-session target uses double progression. The default rep range is 6–10, editable per exercise. If every set hits the top of the range, add weight (+5 lbs upper body, +10 lbs lower body). Otherwise, beat your best set by one rep at the same weight.
- Default sets per exercise is 2 to failure, or 3 for upper chest, legs and lat-focused back lifts (pull-ups, chin-ups, pulldowns, pullovers).
- Weeks run Sunday to Saturday. The weekly streak counts consecutive weeks with 4+ sessions.

### Screens

| Tab | What's there |
| --- | --- |
| Log | Week strip, streak, quick body weight entry, current session |
| History | Every session with sets, volume, PRs, edit and delete |
| Progress | Muscle heat map (front and back body, darker blue = more sets per week), e1RM over time, volume per session, weekly sets per muscle group (4w / 3m / 6m / all) |
| Body | Weigh-ins as dots with a 7-day average line, change since start and over 4 weeks |
| Stats | Workouts this week, streak, PRs with dates, next targets, relative strength |
| Exercises | One collapsible section per muscle category. Open one to set each lift's muscle group, sets and rep range |

## Day and night theme

The palette is light from first light to last light (civil twilight, sun 6° below the horizon) and dark the rest of the day, with a 2.4s color fade at each switch. The default location is Champaign, IL. Des Plaines or custom coordinates can be set in the settings menu. The sun/moon button in the header previews the fade. A preview holds until the next real switch.

## Data and sync

- When opened as a Claude artifact, data is stored in your private per-account store and syncs across devices. A local copy plus a pending-changes queue means logging works offline and syncs later.
- On GitHub Pages, data syncs through Supabase once `window.OVERLOAD_SUPABASE` in `head.html` has your project URL and anon key and you sign in from the gear menu. Same local copy and offline queue, plus live updates between devices.
- With no Supabase config (or opened as a local file), the app falls back to `localStorage` on that device only.

### Supabase setup

1. Create a project at supabase.com.
2. SQL Editor: run `supabase/schema.sql` (one `overload_entries` table with row level security, added to realtime).
3. Authentication > Users > Add user: your email and a password, with Auto Confirm on.
4. Authentication > Sign In / Providers: turn off "Allow new users to sign up" so nobody else can make an account.
5. Project Settings > API: copy the Project URL and the anon public key into `head.html`, run `./build.sh`, push.
6. Open the Pages site, tap the gear, sign in. Anything already logged on that device uploads on first sign-in.

### Apple Health steps

Web apps can't read Apple Health, so an iOS Shortcut does it and posts the count to Supabase.

1. SQL Editor: run `supabase/steps.sql` once (after `schema.sql`).
2. In the app: gear menu > Apple Health steps > Create Shortcut key. The key is shown once and only its SHA-256 hash is stored.
3. Follow the in-app guide to build the Shortcut. It runs Find Health Samples (Steps, today, grouped by day), then POSTs `{ p_token, p_steps }` to `/rest/v1/rpc/overload_log_steps` with the anon key.
4. Add a Time of Day automation (11:55 PM daily, Run Immediately) that runs the Shortcut. Extra runs during the day are fine; each one replaces that day's count.

The key can only write step counts as `s:YYYY-MM-DD` rows. It can't read anything. Making a new key turns off the old one. `p_day` (YYYY-MM-DD) is optional and defaults to today in Central time.
- The settings menu (gear icon) has Export JSON, Sets CSV, Body weight CSV and Import JSON (merge) for backups and moving data.

To add your own sync backend, replace `writeOp`, `flush` and `initCloud` in `index.html`. The data shapes stay the same:

```js
// workout
{ id, date: "YYYY-MM-DD", created, exercises: [{ exId, sets: [{ w, r, rpe }] }] }
// weigh-in (keyed by date)
{ date: "YYYY-MM-DD", w }
// meta
{ custom: [{ id, name, group }], ex: { [exId]: { group, sets, min, max } } }
```

## Install on your phone

The GitHub Pages build is an installable web app. It opens full screen with no browser bar and works offline.

- **iPhone:** open the Pages link in Safari, tap Share, then Add to Home Screen.
- **Android:** open it in Chrome and tap Install app (or find it in the ⋮ menu).

On iPhone, the installed app has its own storage, separate from Safari. Data only matches across devices once a sync backend is connected.

## Files

| File | Purpose |
| --- | --- |
| `src/app.html` | App source (same file that runs as the Claude artifact) |
| `head.html` | Pages-only head: manifest link, iOS app tags, base styles, service worker registration |
| `index.html` | Built output, `head.html` + `src/app.html`. Run `./build.sh` after editing either |
| `manifest.json` | App name, icons, standalone display, colors |
| `supabase/schema.sql` | Table and row level security for Supabase sync |
| `supabase/steps.sql` | Apple Health steps: Shortcut key table and the `overload_log_steps` function |
| `sw.js` | Service worker: offline app shell, network-first page loads so updates arrive on next open |
| `icons/`, `favicon.svg`, `apple-touch-icon.png` | Plate stack icons |

When you ship a change, bump `VERSION` in `sw.js` so installed copies drop the old cache.

## Running it

Open `index.html` in a browser, or serve the folder (`python3 -m http.server`) to test the service worker on localhost. GitHub Pages serves it from `main`. Charts load Chart.js 4.4.1 from cdnjs. Supabase sync loads supabase-js 2.45.4 from jsDelivr, only when configured. Fonts are Barlow and Barlow Condensed from Google Fonts.
