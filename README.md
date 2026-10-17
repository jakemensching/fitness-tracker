# Overload Lift Log

A personal, mobile-first workout tracker built around progressive overload and body weight. One file (`index.html`), no build step.

## Features

- **Logging**: sessions with exercises and sets (weight in lbs, reps, optional RPE). 39 preloaded lifts plus custom exercises, each tagged with a muscle group.
- **Beat this**: picking an exercise shows last session's sets and the next target. There are also "Copy last session" and "Fill target" buttons.
- **PR badge** shows the moment a set beats your previous best weight or e1RM.
- **Body weight** logging with a 7-day moving average.
- **Edit or delete** any session or weigh-in.

### Calculations

- Estimated 1RM per set uses Epley: `weight × (1 + reps / 30)`. The best set is the session's e1RM.
- Session volume is the sum of `weight × reps`.
- Bodyweight lifts (pull-ups, chin-ups, dips, hanging leg raise) count body weight plus added weight. Body weight is the 7-day average on that date.
- Relative strength is best e1RM ÷ current 7-day body weight average.
- Next-session target uses double progression. The default rep range is 6–10, editable per exercise. If every set hits the top of the range, add weight (+5 lbs upper body, +10 lbs lower body). Otherwise, beat your best set by one rep at the same weight.
- Default sets per exercise is 2 to failure, or 3 for upper chest, lats and legs.
- Weeks run Sunday to Saturday. The weekly streak counts consecutive weeks with 4+ sessions.

### Screens

| Tab | What's there |
| --- | --- |
| Log | Week strip, streak, quick body weight entry, current session |
| History | Every session with sets, volume, PRs, edit and delete |
| Progress | e1RM over time, volume per session, weekly sets per muscle group (4w / 3m / 6m / all) |
| Body | Weigh-ins as dots with a 7-day average line, change since start and over 4 weeks |
| Stats | Workouts this week, streak, PRs with dates, next targets, relative strength |

## Day and night theme

The palette is light from first light to last light (civil twilight, sun 6° below the horizon) and dark the rest of the day, with a 2.4s color fade at each switch. The default location is Champaign, IL. Des Plaines or custom coordinates can be set in the settings menu. The sun/moon button in the header previews the fade. A preview holds until the next real switch.

## Data and sync

- When opened as a Claude artifact, data is stored in your private per-account store and syncs across devices. A local copy plus a pending-changes queue means logging works offline and syncs later.
- Opened anywhere else (local file, GitHub Pages), the cloud layer is absent. The app falls back to `localStorage` on that device only.
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

## Running it

Open `index.html` in a browser, or enable GitHub Pages on `main`. Charts load Chart.js 4.4.1 from cdnjs. Fonts are Barlow and Barlow Condensed from Google Fonts.
