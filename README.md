# AsanaFit — Full-Body Yoga Coach for iPhone

AsanaFit watches your whole body with the ordinary camera and coaches your yoga alignment in real time. It uses Apple's **Vision** body-pose model: 15 tracked joints, the angles they make, and how steady you hold them. Holds are counted in **breaths**, not reps, because that is how yoga is actually practised.

Everything runs on the device. No frame is recorded, nothing is uploaded, and there is no account.

Unlike its sibling **FaceFit**, this one needs no TrueDepth camera — any iPhone on iOS 17 will do.

## Features

**24 asanas across six groups**
- Standing & legs, balance, core & strength, backbends, hips & forward folds, rest & breath
- Each pose is checked live against real alignment targets: front knee near 90°, back leg straight, spine upright, arms level, hips in one line
- A **correction cue for every target**, so the coach tells you the one thing to fix rather than a score you cannot act on ("straighten your back leg", "sink your hips lower")
- The joints the cue is about light up on the skeleton
- Two-sided poses run left and right, with every cue mirrored automatically
- Gentle / Standard / Precise difficulty widens or tightens every target at once

**Breath-paced holds**
- A hold is a number of breaths, and you set how long a breath is (3–10 s), so five breaths is a real, adjustable length of time
- An expanding dot paces the inhale and exhale, with a longer exhale than inhale
- A wobble **pauses** the hold instead of resetting it. Five breaths in a shape you keep finding your way back into is still five breaths of practice
- Voice coach and haptics throughout, which matters more here than in any other kind of fitness app: in half of these poses your head is turned, upside down or your eyes are shut

**Framing that tells you the truth**
- The preview is shown whole rather than cropped, so you see exactly what the app can see
- Live framing check: "step back", "step closer", "get your whole body in frame", "move to the middle"
- A single camera cannot see depth, so **each pose says which way to stand.** A twist or a fold is judged side-on, a wide stance front-on. The app detects which way you are facing from your shoulder width and waits until you have turned

**Body Scan (9 guided steps, about 2 minutes)**
- Stand tall front-on, stand tall side-on, reach overhead, fold forward, squat, balance on each foot, bend to each side
- Produces a **Body Score** out of 100 from four pillars: **Flexibility** (30%), **Posture** (25%), **Balance** (25%), **Mobility** (20%)
- Levels: Getting started → Building → Steady → Strong → Advanced
- A radar chart with your previous scan ghosted behind it, and the change in every score
- Measurements in real units: fold depth in degrees of hip flexion, overhead reach in degrees, squat depth in torso lengths, side bend in degrees, one-leg hold in seconds, shoulder and hip level in degrees
- Left and right reported separately wherever there are two sides, with a **percentage even** figure

**Six body areas, scored and coached**
- Hamstrings & back line, hips & ankles, shoulders, spine, balance, alignment
- Each gets a 0–100 score, a plain-language insight into what is holding it back, and the poses that train it

**Your practice plan**
- Picks your three weakest areas (goals you choose get pushed up the list), assigns two poses each plus a closing rest, and runs with one tap
- Works from your goals alone before your first scan
- Shown on the Today screen as "Your practice for today"

**Balance test**
- Stand on one foot as long as you can, up to 45 s, then swap. Ends a side when the foot comes down and stays down
- Scores hold time, stillness and how even the two sides are, with advice for each result
- One-leg balance is one of the most trainable measurements in the app, and one of the strongest predictors of staying mobile later on

**8 flows**
- Sun Salutation, Morning Wake-Up, Strong Legs, Core & Strength, Balance Builder, Hips & Hamstrings, Open Your Chest, Wind Down

**Breathing (pranayama)**
- Even Breath, Long Exhale, Box Breath, 4-7-8 and Ocean Breath, with a paced circle, voice and haptics
- No camera needed, so it works lying down with your eyes closed

**Game progression**
- **XP** from every breath held (4 each), finished holds (+20), clean alignment (+10), scans (80), balance tests (40) and breathing practices (20)
- **Levels** with rank names (New to the mat → Beginner → Regular → Practitioner → Devoted → Teacher); level *n* needs `150 × (n−1)^1.5` XP
- **Poses unlock as you level up.** You start with five (Mountain, Forward Fold, Half Fold, Child's Pose, Corpse) and the rest arrive up to level 10; flows unlock between levels 1 and 9. Locked poses stay out of your plan and are skipped in flows
- **Journey map** of every level and what it unlocks
- **Daily quests:** three a day from a pool of twelve, worth 40–70 bonus XP, with progress read straight from your history
- **Mastery stars** per pose at 30, 100 and 250 total breaths
- **Daily XP goal** of 150, plus level-up and unlock celebrations on the summary

**Pose Lab**
- A live readout of all 8 joint angles and 17 alignment measurements, with what each one means, plus left/right balance bars and a front-on / side-on indicator. Use it to see what your own body reads before you trust a target

**Before & after:** two scans side by side, with the change in every pillar, area and raw measurement.

**Progress:** day streaks, a 30-day minutes chart, body score trends across scans, a breakdown of where your breaths go by group, and session history (SwiftData).

**You tab:** name, age, sleep, sitting hours and water (stored on device), all your totals, scan history, badges and settings. A **tip of the day** on the Today screen reacts to those habits and your latest scan.

**Badges:** 14 of them, for streaks, breaths, minutes, the whole library, scores, balance, scans, gold mastery and sunrise practice.

**Daily reminder:** an optional notification at a time you choose.

## Requirements

- An iPhone running **iOS 17 or later**. No TrueDepth or LiDAR needed
- Room to stand 2–3 m from the phone, with something to prop it against
- **Either** a GitHub account (the app is built on GitHub's cloud Macs, and you install it from Windows) **or** a Mac with **Xcode 16 or later**

## Install without a Mac (Windows)

**1. Build in the cloud (free)**
1. Create a repository on GitHub and push this `AsanaFit` folder to it, so `AsanaFit.xcodeproj` sits at the repository root. A public repo gets free macOS build minutes; a private repo uses your monthly free allowance.
2. Each push to `main` runs **Actions → Build iOS app** (about 5–10 min). You can also start it by hand with **Run workflow**.
3. When the run is green, download **AsanaFit-unsigned-ipa** from the run's *Artifacts* section and unzip it to get `AsanaFit-unsigned.ipa`.
4. If the run is red, the run summary lists the compile errors with file and line.

**2. Install on your iPhone with Sideloadly**
1. On Windows, install **Sideloadly** from sideloadly.io, plus the Apple drivers its download page asks for (iTunes / iCloud from apple.com).
2. Connect your iPhone by USB, unlock it and tap **Trust**.
3. Drag `AsanaFit-unsigned.ipa` into Sideloadly, enter an Apple ID, then click **Start**. A secondary Apple ID is fine and is the safer choice.
4. On the iPhone:
   - Turn on **Settings → Privacy & Security → Developer Mode**. The phone restarts.
   - Trust your Apple ID under **Settings → General → VPN & Device Management**.
5. Open AsanaFit and allow camera access.

With a free Apple ID the app stops launching after **7 days**. To refresh it, sideload the same IPA again (Sideloadly can also refresh it automatically over Wi-Fi). A paid Apple Developer account ($99/year) removes that limit and lets you ship through **TestFlight**.

## Run it on a Mac

1. Open `AsanaFit.xcodeproj` in Xcode.
2. Select the **AsanaFit** target → **Signing & Capabilities** → choose your **Team**. Change the bundle identifier (`com.yourname.AsanaFit`) to something unique.
3. Plug in your iPhone, select it as the run destination and press **Run**.
4. On first launch, allow camera access.

**Simulator:** the app runs in **demo mode** with a simulated body that moves into each pose by itself, so you can walk through every screen, pose, flow and the whole body scan without a camera.

## Setting up your space

| Do this | Why |
|---|---|
| Prop the phone 2–3 m away, roughly hip height | Vision needs your whole body, head to feet, inside the frame |
| Stand in the middle of the frame | The app refuses to start a pose until you are framed, and says which way you are off |
| Turn side-on when told | Depth is invisible to one camera. A fold seen from the front is a person standing still |
| Face a window rather than stand in front of one | Backlight is the main cause of dropped joints |
| Wear something that shows your outline | Very loose clothing hides knees and hips |

## Check on a real device

Open **Analyse → Pose Lab** and test these:

| Do this | Expect |
|---|---|
| Stand still, facing the camera | 15 of 15 joints, "Front-on", spine lean under 5° |
| Turn side-on | The badge changes to "Side-on" as your shoulder width drops below 0.40 torsos |
| Bend one knee to a right angle | That knee angle reads about 90° |
| Raise both arms overhead | Arm lift climbs toward 170°, hand height toward 2 torsos |
| Fold forward, side-on | Hip angle drops from 180° toward 60° |
| Lift one foot | Foot lift rises above 0.25 torsos |

**Left/right:** Vision labels joints from the body's own anatomy, and the frames it analyses are deliberately *not* mirrored, so "left knee" really is your left knee even though the preview you see is mirrored. If a pose ever coaches the wrong side on your device, swap the joints in that asana's requirements in `AsanaLibrary.swift`.

## Project structure

```
AsanaFit/
├── .github/            Cloud build (GitHub Actions on macOS) → unsigned .ipa
├── AsanaFit.xcodeproj
└── AsanaFit/
    ├── App/            App entry, tab root, onboarding, settings keys
    ├── Tracking/       Camera + Vision → PoseSample, joint geometry, framing, skeleton overlay
    ├── Poses/          Asana model + alignment targets, library, stick-figure builder, hold engine, breath pacer
    ├── Analysis/       Body scan steps, scan engine, scoring, practice plan, balance test
    ├── Data/           SwiftData models, XP and unlocks, quests, badges, habits
    ├── Services/       Voice coach + haptics, daily reminder
    ├── Views/          Today, Practice, Analyse (scan, Pose Lab, balance, compare), Breathe, Progress, You, Settings
    └── Assets.xcassets App icon, accent colour
```

### How it works

- **`BodyTracker`** runs an `AVCaptureSession` on the front camera and hands each frame to `VNDetectHumanBodyPoseRequest` at about 20 Hz. The frames Vision sees are rotated upright and **not** mirrored; only the preview you watch is mirrored. Joints are smoothed with a confidence-weighted filter so a held pose does not flicker. With no camera, it simulates a body instead.
- **Everything is measured in torso lengths.** Normalised camera coordinates are squashed by the frame's aspect ratio, so the tracker corrects for that first, then expresses every distance as a fraction of the neck-to-hips distance. That makes measurements independent of how far away you stand.
- **An asana** is a list of `Requirement`s over `BodySignal`s: `.atLeast(.angle(.rightKnee), 150, "Straighten your back leg")`, `.near(.pair(.leftHip), 85, 24, "Lift your hips into a long V")`, `.atMost(.metric(.spineTilt), 12, "Don't lean")`. A `.pair` averages the left and right version of an angle and can also measure how even they are.
- **Alignment** is the mean of every requirement's progress, where 1.0 means met. Missing a target by more than its window (40–45° for angles) scores zero for that target. The worst requirement supplies the cue and the highlighted joints.
- **`AsanaEngine`** runs framing → settle → hold → done. During the hold, alignment may dip to 0.78 before the hold pauses; five seconds out of the shape sends you back to settling. Breaths are counted from the time actually held.
- **The stick figure is generated, not drawn.** Each asana carries a `FigurePose`: ten limb directions in degrees. `SkeletonBuilder` turns that into joint positions with average human proportions, and the same numbers produce the animated demo, the faint guide drawn behind you on camera, and the simulated body in demo mode.

### Add an asana

Add an entry to `AsanaLibrary`:

```swift
Asana(
    id: "chair", name: "Chair", sanskrit: "Utkatasana", category: .standing,
    symbol: "figure.strengthtraining.functional",
    summary: "…", benefits: "…", steps: ["…"],
    facing: .side,
    requirements: [
        .atMost(.pair(.leftKnee), 130, "Sit lower, bend your knees more"),
        .atLeast(.metric(.handHeight), 1.3, "Reach your arms up alongside your ears"),
    ],
    figure: FigurePose(spine: 30, head: 25,
                       leftUpperArm: 18, leftForearm: 14, rightUpperArm: 14, rightForearm: 10,
                       leftThigh: 142, leftShin: 200, rightThigh: 138, rightShin: 198),
    holdBreaths: 5, twoSided: false, level: .intermediate
)
```

Directions in a `FigurePose` are absolute, in degrees clockwise from straight up as the viewer sees it: 0 is up, 90 right, 180 down, 270 left. Write two-sided poses for the **left** side, facing the camera's right; `Asana.mirrored` produces the other side and swaps the words "left" and "right" in every cue.

Then give it an unlock level in `Progression.unlockLevels`, and use **Pose Lab** to see what your body actually reads before you settle on thresholds.

## What a single camera cannot do

This is the honest limit of the approach, and the app is built around it rather than pretending otherwise:

- **No depth.** Every angle is the *projected* angle on a flat image. A front knee bent 90° in three dimensions may read 110–120° from the front, which is why the targets are set against projected values and are deliberately wide.
- **Poses are judged from one side only.** That is why each asana declares `.front` or `.side`, and why the app waits until you have turned before it starts.
- **Rotation is invisible.** Twists, foot position and hip rotation are not measured. The app does not claim to check them.
- **The demo guide is approximate.** The faint shape drawn behind you is a proportional reference, not a per-body target.

## Tuning notes

- Thresholds are starting points. Use the Gentle / Standard / Precise setting first; it widens or tightens every target at once through one `tolerance` number.
- To change one pose, edit its `requirements` in `AsanaLibrary.swift`. `window` on `BodyAngle` and `BodyMetric` sets how much partial credit a near miss earns.
- Scan scoring lives in `BodyScoring`, where every threshold is written as a `best` and a `worst` value in real units — e.g. a forward fold scores 100 at 40° of hip angle and 0 at 110°.
- `AVCaptureConnection.videoOrientation` is soft-deprecated in the iOS 17 SDK but still the simplest way to get upright frames, so you may see a deprecation warning.

## Disclaimer

AsanaFit is a wellness and training tool, **not a medical device**. It does not diagnose or treat any condition, and it cannot tell you whether a pose is safe for your body. If you are pregnant, recovering from an injury, or have a condition affecting your joints, spine, blood pressure or balance, talk to a clinician or a qualified teacher before starting. Come out of any pose that hurts.
