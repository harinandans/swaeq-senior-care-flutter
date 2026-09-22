# SwaEQ Senior Care (Flutter)

Android app for the senior daily-routine product. Design language matches
[`flutter-mock-app`](../flutter-mock-app); feature set is senior-only.

## What it does

- **Login:** WhatsApp-styled OTP (demo — any 10-digit phone, any 6-digit OTP via existing `/auth/otp/*`)
- **No multi-step onboarding** — after verify you go straight to Today
- **Tabs:** Today · Learn · Reminders · Me
- **APIs:** `/senior/today`, `/senior/home`, `/senior/content`, `/senior/reminders`, quizzes, programs
- **In-Video Quizzes:** Timed quizzes that pause playback to engage users

## In-Video Quiz Feature

The app supports data-driven in-video quizzes that pause playback at configured timestamps to engage users with educational questions.

### Configured Quiz

**Video:** Pranayama / Breathing Exercise (`scn-pranayama`, `pranayama` slot, or URL containing `Breathe_9_16`)

**Trigger timestamp:** 15 seconds into the video

**Question:** "What is the main benefit of deep breathing exercises?"

**Options:**
- A) Builds muscle strength
- B) Reduces stress and calms the mind ✓ (correct)
- C) Improves eyesight
- D) Makes you feel hungry

**Explanation:** Deep breathing activates your body's relaxation response. It lowers heart rate and blood pressure, helping you feel calm and focused. Practice this daily for better stress management!

### Quiz UX

1. Video pauses automatically at the configured timestamp
2. A full-screen overlay appears with the question and options
3. User selects an answer (or taps "Skip" to skip)
4. Correct/incorrect feedback and explanation are shown
5. User taps "Continue Video" to resume playback
6. Quiz triggers only once per playback session; restarting video (seek to start) allows re-triggering

### Adding a New Quiz

Edit `lib/models/video_quiz_config.dart` and add a new `VideoQuizConfig` to the `VideoQuizRegistry.quizzes` list:

```dart
static const _myNewQuiz = VideoQuizConfig(
  id: 'unique-quiz-id',
  videoMatcher: VideoMatcher(
    contentId: 'scn-my-video',     // Match by content ID
    slotId: 'my-video',            // OR by slot ID
    urlContains: 'MyVideo_9_16',   // OR by URL substring
  ),
  triggerTimestamp: 30,            // Seconds into video
  question: 'Your question here?',
  options: [
    VideoQuizOption(id: 'a', text: 'Option A', isCorrect: false),
    VideoQuizOption(id: 'b', text: 'Option B', isCorrect: true),
    VideoQuizOption(id: 'c', text: 'Option C', isCorrect: false),
  ],
  explanation: 'Explanation shown after answering.',
  showContinueButton: true,        // true = explicit Continue button
);

// Add to quizzes list:
static const List<VideoQuizConfig> quizzes = [
  _pranayamaQuiz,
  _myNewQuiz,  // Add here
];
```

### Senior-Friendly Design

- Large touch targets (minimum 56dp)
- High contrast text on dark overlay
- Clear visual feedback for correct/incorrect answers
- Skip option always available
- Accessible semantics for screen readers
- **Text-to-Speech:** Question and options read aloud automatically; tap speaker icon to re-read

## Video Player Improvements (QA Items)

### 1. End-of-Video Buffering Fix

**Issue:** Buffering spinner flashed in the last ~2 seconds of videos (e.g., Panchang content).

**Fix:** The buffering indicator is now suppressed when:
- Video position is within 2 seconds of duration
- Video has completed playback
- Quiz overlay or completion overlay is visible

**Verify:** Play any short video to completion — no spinner flash in the final moments.

### 2. Post-Video Completion Overlay

**Issue:** Users were stranded after catch-up videos finished with no clear next action.

**Fix:** A senior-friendly completion overlay now appears when video ends, offering:
- **Back to Today** (primary action) — returns to the timeline
- **Play Next** (if API provides nextContentId) — plays the next video
- **Replay** — restarts the current video

**Verify:** Watch any video to completion — the overlay appears with large, clear buttons.

### 3. Left-Center Return Button

**Issue:** Tech preferred the earlier left-center return button over the top-right X.

**Fix:** A large (56dp) left-center arrow-back button replaces the top-right X close button when controls are visible. The button has:
- Black semi-transparent background
- Large touch target
- Accessibility label "Return to previous screen"

**Verify:** During video playback, tap to show controls — the return button is on the left side, vertically centered.

### 4. Quiz Text-to-Speech (TTS)

**Feature:** Quiz overlay now reads the question and all options aloud using Flutter TTS.

**Behavior:**
- TTS starts automatically when quiz appears
- Speech rate is slower (0.45) for senior comprehension
- Speaker icon in header allows on-demand re-read
- TTS stops immediately on: Skip, answer selection, Continue, or overlay dismiss

**Verify:** Trigger the Pranayama quiz at 15s — the question and options are read aloud. Tap the speaker icon to re-read. Select an answer — TTS stops.

## Testing Notes

- **Time-lock disabled:** `AppConfig.lockFutureSlotsByTime = false` — all timeline tiles are active for testing. Do NOT re-enable.
- **Mock videos:** If API content unavailable, mock videos from CloudFront are used as fallback.

Package id: `com.vidarka.swaeq_senior`

## Transfer to x86 server & build APK

Copy this whole folder (not the parent repo) to a linux/amd64 machine with Docker:

```bash
# from your laptop
rsync -av --exclude build --exclude .dart_tool \
  senior-care/ user@x86-server:~/senior-care/

# on the x86 server
cd ~/senior-care
docker build -t swaeq-senior-apk .

# optional custom API:
# docker build --build-arg API_BASE_URL=https://your-api.example.com -t swaeq-senior-apk .

docker run --rm -v "$PWD:/host" swaeq-senior-apk \
  cp /out/swaeq-senior.apk /host/swaeq-senior.apk

ls -lh swaeq-senior.apk
```

Or use the helper script:

```bash
./scripts/build-apk.sh
# APK → build-output/swaeq-senior.apk
```

Sideload `swaeq-senior.apk` on an Android phone.

**Note:** Build must run on **linux/amd64** (AWS x86 / CodeBuild). Prefer that over Apple Silicon Docker emulation.

## Default API

`https://5on0mm6m5d.execute-api.ap-south-1.amazonaws.com`

Senior routes must be deployed for Today/Learn content. Login works against existing auth even before senior deploy.

Seed demo content (on API host):

```bash
cd api && STAGE=dev node scripts/seed_senior_content.js
```

## Fallback Dockerfile

If GHCR Flutter image is unavailable:

```bash
docker build -f Dockerfile.from-scratch -t swaeq-senior-apk .
```
