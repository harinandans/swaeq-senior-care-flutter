# Tech feedback v7 — verification guide

Senior Care Flutter (Origin main). Package `com.vidarka.swaeq_senior`.

## Hard constraints (unchanged)

- Lazy TTS only (`LazyTtsPlugin` / `lazy_tts_service.dart`) — no stock `flutter_tts`
- `AppConfig.lockFutureSlotsByTime = false` (test builds)
- Release APK: arm64-v8a only
- Video player: wakelock, HLS, quiz overlay, left-center back, near-end buffering suppress, completion overlay

---

## Tech items

### 1) Today `0/N done` updates

- **Behavior:** Slot completion is stored locally (`LocalStore`) and merged into Today on every load. API `completeSeniorSlot` is attempted when marking done or when a timeline video finishes.
- **Verify:** Open Today → note `X / N done` → watch a timeline video to end → Back to Today → count increases (even if API fails, local merge applies).

**Persistence:** Local (`shared_preferences` keys `slot_done_{date}_{slotId}`) + API when available.

### 2) After watch → focus next incomplete slot

- **Behavior:** Timeline opens pass `slotId`, `date`, `fromToday=1`. On “Back to Today”, navigates to `/today?scrollToNext=1&afterSlot=…` and scrolls to the next incomplete video slot.
- **Verify:** Complete an early slot video → Back to Today → list scrolls to next undone video card.

### 3) Post-video like + comment

- **Behavior:** When playback completes, bottom sheet: Like + optional comment. Saved locally; `POST /senior/content/:id/engagement` attempted (ignored on 404).
- **Verify:** Finish any video → sheet appears → save → reopen video and complete again (like state from local store on load).

### 4) In-player reactions

- **Behavior:** Floating chips (namaskar, heart, clap, flower) during playback; counts in `LocalStore`; non-blocking.
- **Verify:** Play video → tap reactions → counts increment.

### 5) Local reminders (sound + vibration)

- **Behavior:** `NotificationService` reminder channel and scheduled notifications use `playSound: true`, `enableVibration: true`, `@mipmap/ic_launcher`. Permissions requested async after init.
- **Verify:** Reminders tab → schedule test (if available) or sync reminders → notification fires with sound/vibration (device settings permitting).

### 7) Share

- **Behavior:** `share_plus` on completion overlay; shares title + `https://care.swaeq.app/watch/{contentId}` (deep link placeholder; WhatsApp via system share sheet).
- **Verify:** Complete video → Share → pick WhatsApp or other app.

---

## Games tab (new)

- **Nav:** Bottom bar order: Today | Learn | **Games** | Reminders | Me
- **Learn:** CMS rails only; link to Games tab (old Brain & Fun API stub removed)
- **Hub:** `/games` — 15 large cards
- **Play:** `/games/play/{id}`

### Game roster (first-party MIT, `lib/games/`)

1. tube-sort — Colour Tube Sort  
2. memory-match — Memory Match  
3. color-path — Colour Path  
4. pattern-repeat — Pattern Repeat  
5. number-order — Number Order  
6. spot-difference — Spot the Difference  
7. jigsaw-lite — Jigsaw Lite  
8. word-search — Word Search  
9. sudoku-easy — Sudoku Easy (4×4)  
10. mahjong-lite — Mahjong Lite  
11. bubble-pop — Bubble Pop  
12. sliding-puzzle — Sliding Puzzle  
13. tangram — Shape Fit  
14. calm-coloring — Calm Coloring  
15. breathing-dots — Focus Dots  

**Verify:** Games tab → open each game → Reset works → complete a round.

No GPL / third-party game code vendored.

---

## Deferred / follow-up

- **Offline quiz audio:** Pre-recorded Q/A assets for Pranayama quiz (lazy TTS remains primary).
- **Engagement API:** Backend may not implement `/senior/content/:id/engagement` yet; client persists locally.

---

## Build

```bash
flutter build apk --release --target-platform android-arm64
```

Artifact: `senior-care-quiz-v7-arm64.apk`
