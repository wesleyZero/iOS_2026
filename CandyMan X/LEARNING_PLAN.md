# CandyMan → Top 1% iOS Engineer

A 26-week plan that **rebuilds CandyMan from scratch in a fresh repo**, the right way, while developing every skill needed to be hired at Apple, top startups, or to ship as an independent.

The existing `CandyMan X` codebase is your **reference implementation** and your **product spec**. You will read it, learn from it, and improve on it — but every line of the new app gets written by you, deliberately, with you understanding *why* you wrote it that way.

**Calibration:**
- Background: 2–5 yrs general programming, new to Swift/iOS
- Pace: 15–20 hrs/week (≈18 hrs avg)
- Target: hireable at FAANG / top startup / indie-capable
- Total budget: ~470 hours over 26 weeks

**The thesis.** "Top 1%" is the union of three things: (1) you can build *anything* on Apple platforms because you understand how the platforms work, not just which API to call; (2) you can defend your architectural choices because you know the alternatives; (3) you ship — your work runs in production for real users. Rebuilding CandyMan, a real precision-dosing calculator with sig fig propagation, multi-mode persistence, calibration, and crash reporting, exercises all three.

---

## What CandyMan actually is (the product spec you'll rebuild)

CandyMan is a **precision gummy-batch formulation app** for hobbyist chemists. The user picks a mold geometry, an active substance and dose, flavors/colors/terpenes, and the app produces a complete recipe — three mix groups (Activation, Gelatin, Sugar) summing exactly to the target pour volume. It must be correct to chemistry-grade tolerances and respect significant figures. It runs offline, persists batches and templates, supports calibrated scales/syringes/containers, and includes a custom crash reporter for safety-critical use.

The current vibe-coded version (in `CandyMan X/CandyMan/`) has ~50 files and these feature areas:

| Feature area | Files in current repo | Skills it forces |
| --- | --- | --- |
| Domain model (substances, molds, units) | `Models.swift` | Value types, enums, protocols |
| Pure calculation engine | `BatchCalculator.swift` | Pure functions, testability, numerical correctness |
| Sig fig propagation | `SigFigs.swift`, `SigFigsTests.swift` | Algorithms, parsing, property-based testing |
| Persistence (SwiftData) | `SavedBatch.swift`, `BatchTemplate.swift` | SwiftData, schema migration |
| Global config & defaults | `SystemConfig.swift` | Tiered defaults, UserDefaults, JSON |
| Pickers (shape/scale/syringe/...) | `ShapePickerView`, `ScalePickerSheet`, ... | SwiftUI composition, sheet patterns |
| Calibration (mold, equipment) | `MoldCalibrationView`, `MeasurementEquipmentView` | Form design, validation |
| Multi-active batches | `MultiActiveBatchOutputView` | Complex view models |
| Themes & accent colors | `Theme.swift`, `ThemePickerView` | Design system, dynamic theming |
| Crash reporting | `CrashReporter.swift` | Signal handlers, breadcrumbs, file IO |
| Tests | `CandyManTests/` (8 files) | XCTest, fixtures, integration tests |

Your rebuilt version will hit the same product surface — and add: cloud sync, widgets, App Intents, full accessibility, modular SPM packages, 80%+ coverage, CI/CD, App Store launch.

---

## How the plan is structured

Each week has three things:

1. **Build.** A specific feature or refactor of new-CandyMan. ~70% of your time. Code first, read second.
2. **Study.** The concepts the build forces you to learn. ~25%.
3. **Drill.** A small, time-boxed exercise — a LeetCode problem, a WWDC video, a one-page write-up. ~5%, but every week.

Two parallel weekly tracks (running every single week):
- **CS & Interview Prep** — 3 hrs/wk
- **Craft & Community** — 2 hrs/wk

These are non-negotiable. They are why the plan ends with you employable, not just with a finished app.

**One repo discipline.** Create a fresh repo today: `~/Documents/Code/iOS/CandyMan-v2/`. The vibe-coded `CandyMan X` stays untouched as your reference. Every week you compare your week's output to the equivalent in the reference repo — learning what they got right and what you can do better.

---

## Phase 1 · Swift & Xcode Foundations (Weeks 1–3)

**Goal:** read any Swift code without flinching. Know your tools. The current `Models.swift` and `BatchCalculator.swift` should feel obvious by week 3.

### Week 1 — Swift the language, via the domain model
**Build:** In a fresh project, recreate the core domain model from scratch — `GummyShape`, `Active`, `ConcentrationUnit`, `GummyColor`, `TerpeneFlavor`, `FlavorOil`. Use raw-value enums. Add a `BatchComponent` struct and a `MixGroup` struct. No views yet. Just a model module that compiles and a `main.swift` that prints a sample batch description.
**Study:** value vs reference types, optionals, generics, enums with associated values, protocols (no associated types yet), error handling, `Codable`. Read the first 5 chapters of *Hacking with Swift*.
**Drill:** Two LeetCode easies in Swift. Write one paragraph: "Why is `Active` an enum and not a struct?"
**Reference compare:** Open `CandyMan X/CandyMan/Models.swift` only at the end of the week. Note 3 things it does that yours doesn't.

### Week 2 — Memory, ARC, value semantics — via the calculator engine
**Build:** Port `BatchCalculator` to your new repo as a pure function. No SwiftUI, no state. Input: a snapshot struct. Output: a `BatchResult`. Write a tiny CLI driver that prints results for 5 test inputs.
**Study:** ARC, strong/weak/unowned, closures capture semantics, copy-on-write for collections, `inout`, why pure functions are easier to test. Watch WWDC "Explore Swift performance" (2024).
**Drill:** Force a retain cycle on purpose elsewhere, find it in Instruments, fix it. Write the three rules of ARC from memory.

### Week 3 — Xcode, Git, SPM, Instruments — via project setup
**Build:** Restructure new-CandyMan as a workspace. Extract the model + calculator into a Swift Package called `CandyKit`. Add SwiftLint and SwiftFormat. Set up `.gitignore`, conventional commits, a feature-branch workflow. Push to a fresh GitHub repo.
**Study:** Xcode build system, schemes, configurations, debug symbols, SPM manifests, Instruments overview. Read how Apple structures its sample code projects.
**Drill:** Profile cold launch with Time Profiler — even on a near-empty app, build the muscle.

**Phase 1 milestone:** new-CandyMan compiles, `CandyKit` is a separate SPM package with a passing test that calls `BatchCalculator.compute(...)` and asserts on the output. You can explain ARC without notes.

---

## Phase 2 · SwiftUI & UIKit Bridge (Weeks 4–7)

**Goal:** rebuild the entire visible surface of CandyMan, screen by screen, with intent.

### Week 4 — SwiftUI fundamentals via `ShapePickerView`
**Build:** Recreate the shape picker as your first real screen. A grid of 7 `GummyShape` cards using SF Symbols. Tap a card → push a placeholder detail screen. Use `@State`, `@Binding`, `@Observable`. Use `NavigationStack`.
**Study:** view identity vs lifetime, the SwiftUI rendering model, how `@State` actually works under the hood. Read Apple's "Managing model data in your app."
**Drill:** Recreate one screen of Apple's Reminders or Notes app for a comparison.
**Reference compare:** Open the existing `ShapePickerView.swift`. Note its accessibility, theming, and animation choices.

### Week 5 — Layout, animation, gestures via `ScalePickerSheet` & `SyringePickerSheet`
**Build:** Rebuild the scale and syringe picker sheets. These are your first sheet presentations. Add animations on selection. Build a custom horizontal carousel layout for syringe sizes. Add haptic feedback on selection.
**Study:** SwiftUI layout protocol, `GeometryReader` (and when not to use it), `matchedGeometryEffect`, animation curves, gesture composition, sheet presentation detents.
**Drill:** Pause one Apple system animation and sketch its geometry math.

### Week 6 — Forms, validation, accessibility via `MoldCalibrationView`
**Build:** Rebuild mold calibration: a form where the user enters per-cavity volumes and total cavities for each shape. Validate as they type. Make every field pass Accessibility Inspector at AAA. Verify Dynamic Type up to AX5.
**Study:** Form/Section composition, focused field bindings, formatters, accessibility traits, rotors, custom actions, Dynamic Type design.
**Drill:** Use new-CandyMan with VoiceOver for 10 minutes. Fix every bad label.

### Week 7 — UIKit interop via the custom keypad
**Build:** The current app has a custom numeric keypad (referenced in `NumericInputMode` and `ScribbleKiller`). Rebuild it in UIKit and bridge it via `UIViewRepresentable`. Decide *why* it's UIKit — and document that decision in a comment.
**Study:** UIKit lifecycle, view controllers, AutoLayout basics, `UIViewRepresentable`, when SwiftUI is the wrong tool. Skim *Thinking in SwiftUI* by objc.io.
**Drill:** Read appendix A below; write your own SwiftUI-vs-UIKit decision matrix specific to CandyMan.

**Phase 2 milestone:** new-CandyMan has the shape picker, scale/syringe/mold pickers, and a working calibration form — all accessible, animated with intent, and with the custom keypad bridged from UIKit.

---

## Phase 3 · Architecture & Concurrency (Weeks 8–12)

**Goal:** the part that separates senior from staff. Make new-CandyMan modular, testable, and concurrency-safe.

### Week 8 — MVVM done right, via `BatchConfigViewModel`
**Build:** Rebuild `BatchConfigViewModel` as the central source of truth for an in-progress batch. Inject it via `.environment(...)`. Move all business logic out of views. Add a `BatchOutputView` driven entirely by computed view-model state.
**Study:** MVVM vs MV vs MVC trade-offs, why the SwiftUI community debates view models, the `@Observable` macro internals.
**Drill:** Read one Point-Free episode on architecture. Write a 200-word "what I learned."

### Week 9 — Modularization
**Build:** Split new-CandyMan into feature modules: `BatchFeature`, `CalibrationFeature`, `TemplatesFeature`, `SettingsFeature`, plus shared `DesignSystem` and the existing `CandyKit`. Each is its own SPM package.
**Study:** module boundaries, public/internal access, build-time benefits, how Airbnb / Lyft / Spotify structure their iOS monorepos.
**Drill:** Diagram new-CandyMan's module graph. Identify any cycles.

### Week 10 — async/await via batch save & template loading
**Build:** Add an async `BatchRepository` that loads templates and saves batches. Even though the current app stores locally, model the repository as if it were remote — `func loadTemplates() async throws -> [BatchTemplate]`. Convert any callbacks to async/await.
**Study:** structured concurrency, `Task`, `TaskGroup`, cancellation, `AsyncSequence`. Read SE-0296, SE-0304, SE-0306.
**Drill:** Convert a callback snippet to async/await without notes.

### Week 11 — Actors & Swift 6 concurrency via `CrashReporter`
**Build:** Rebuild `CrashReporter` as an actor. Its breadcrumb buffer is currently guarded by `NSLock` — use the actor model instead. Turn on Swift 6 strict concurrency. Fix every `Sendable` warning across new-CandyMan.
**Study:** actor isolation, `@MainActor`, `Sendable`, global actors, data-race safety. The hottest senior iOS interview topic in 2026.
**Drill:** Explain in writing: why does `@MainActor` exist when actors already serialize access?

### Week 12 — SwiftData and schema migration
**Build:** Add SwiftData persistence for `SavedBatch`, `BatchTemplate`, and the `Tare`/`DryWeight`/`Dehydration` records. Reproduce the current app's "incompatible store → delete and recreate" recovery, but properly: write a real schema migration plan with a `VersionedSchema` and one migration step.
**Study:** SwiftData architecture, persistence stores, migrations, fetch descriptors, `@Query`. The new schema migration APIs in iOS 18.
**Drill:** Force a migration manually by changing a property on a model and migrating from v1 → v2.

**Phase 3 milestone:** new-CandyMan compiles under Swift 6 with zero concurrency warnings, has modular SPM feature packages, an actor-based crash reporter, and SwiftData with a real migration.

---

## Phase 4 · Networking, Auth & Quality (Weeks 13–17)

**Goal:** production-grade reliability. The current app is local-only — the rebuild adds cloud sync and the testing rigor that ships at Stripe.

### Week 13 — Cloud sync layer
**Build:** Add a sync backend. Easiest path: CloudKit via SwiftData's CloudKit integration — `SavedBatch` and `BatchTemplate` sync across the user's devices. Handle conflict resolution (last-writer-wins is fine to start, but document why).
**Study:** CloudKit's eventual consistency, zone-based data, sharing, conflict resolution. URLSession architecture for the day you outgrow CloudKit.
**Drill:** Two-device test (or simulator + device). Force a conflict, watch it resolve.

### Week 14 — Auth & Keychain
**Build:** Add Sign in with Apple as an optional account layer (the app must still work signed-out). Store the auth token in Keychain. Gate sync on auth.
**Study:** OAuth/OIDC flows, PKCE, Keychain access groups, App Attest, Sign in with Apple's privacy model.
**Drill:** Threat-model new-CandyMan's auth in writing.

### Week 15 — Sig figs done right: property-based testing
**Build:** Rebuild `SigFigs.swift` with 100% test coverage. Use the **swift-testing** framework (the new `@Test` system) plus property-based tests via `swift-testing` parameterized tests: for any (a, b) with known SF, `(a*b).sigFigs == min(a.sigFigs, b.sigFigs)`. Get `CandyKit` to 90% line coverage.
**Study:** the testing pyramid, fakes vs mocks vs stubs, dependency injection for testability, the new Swift Testing framework. Read about property-based testing (Hypothesis-style).
**Drill:** TDD a new feature — write the test first, watch it fail, make it pass.

### Week 16 — UI testing & CI
**Build:** Add UI tests with the page-object pattern for three flows: (1) configure and view a batch, (2) calibrate a mold, (3) save and reload a template. Set up GitHub Actions to run unit + UI tests on every PR. Block merges on red CI.
**Study:** XCUITest, accessibility identifiers, flake reduction strategies, parallel testing, Xcode Cloud vs Fastlane vs GH Actions trade-offs.
**Drill:** Cause a flaky test on purpose, fix it three different ways.

### Week 17 — Observability, replacing the homemade crash reporter
**Build:** The current app has a clever DIY `CrashReporter`. For v2, replace it with a real solution (Sentry or Crashlytics) — but keep the breadcrumb pattern. Add structured logging with `OSLog` / `Logger`. Add a feature-flag system.
**Study:** signposts, `os_log` levels, sampling, PII filtering. Read what the original `CrashReporter.swift` got right and wrong.
**Drill:** Force a crash, trace it from device → dashboard → fix → verify.

**Phase 4 milestone:** new-CandyMan has cloud sync, optional auth, 70%+ coverage, green CI on every PR, real crash reporting. This is shipping-quality.

---

## Phase 5 · Performance & Apple Platform (Weeks 18–21)

**Goal:** the polish that turns a good app into a "wow" app — and the platform breadth interviewers love.

### Week 18 — Performance
**Build:** Profile new-CandyMan cold start, `BatchOutputView` render time, scroll on the batch history. Get cold start under 200ms, scroll at flat 60/120fps. Eliminate hitches.
**Study:** Time Profiler, Allocations, Hitches, Animation instruments. The iOS rendering pipeline. `CADisplayLink`. SwiftUI view-update debugging with `_printChanges()`.
**Drill:** Identify and fix one main-thread offender. Document before/after numbers in your README.

### Week 19 — Widgets & App Intents
**Build:** A widget that shows your most-recent batch's summary line ("MDMA · 100mg · Hearts · ready in 4h"). App Intents so users can say "Hey Siri, start a new MDMA batch in CandyMan" and land on a pre-configured `BatchConfigView`.
**Study:** WidgetKit timeline model, `AppIntent`, parameter resolution, intent donations, the Shortcuts surface area.
**Drill:** Make Siri start a batch via voice. (Shockingly satisfying.)

### Week 20 — Notifications & background
**Build:** Add a "gummies are ready" timed local notification when a batch is in dehydration. Add a Live Activity for an active dehydration cycle in the Dynamic Island. Add a `BGTaskScheduler` task that pre-syncs templates.
**Study:** UNNotification framework, Live Activities, Dynamic Island, background modes (and how stingy iOS is about them).
**Drill:** Watch the WWDC "What's new in background tasks" video. Write down three reasons your background task might never run.

### Week 21 — Multi-platform: iPad, watchOS, visionOS
**Build:** The current app locks to portrait — for v2, embrace iPad with `NavigationSplitView` (mold list on the left, batch detail on the right). Add a watchOS companion that shows the active batch timer. Stretch goal: a visionOS scene of a 3D mold preview.
**Study:** watch connectivity, iPad multitasking, visionOS basics. iPad-specific gestures (Pencil, hover).
**Drill:** Use new-CandyMan for one full day on iPad only.

**Phase 5 milestone:** new-CandyMan feels like an Apple-built app — fast, present everywhere, integrated with the system.

---

## Phase 6 · Ship, System Design & Interview (Weeks 22–26)

**Goal:** turn new-CandyMan into a real shipped product *and* yourself into a candidate top companies fight for.

### Week 22 — App Store launch
**Build:** Polish every screen. Write App Store copy (carefully — this app's domain may need positioning as a *general* precision-dosing chemistry tool to pass review; Apple is conservative). Take screenshots (10 per device size). Configure App Store Connect. Submit to TestFlight, then production.
**Study:** App Store review guidelines (read all of them — pay extra attention to controlled-substance policies; you may need to position the app differently for review). Privacy nutrition labels. ATT prompts. ASO basics.
**Drill:** Get five real users on TestFlight. Read their feedback verbatim.

### Week 23 — Mobile system design
**Build:** Pick three classic mobile system design problems (Instagram feed, Uber-style real-time location, offline-first notes app — *the third is essentially CandyMan*). Design each in writing with diagrams, like you're whiteboarding it.
**Study:** caching, pagination, offline-first patterns, conflict resolution, scaling mobile clients, on-device ML where relevant.
**Drill:** Record yourself explaining one design in 30 minutes. Watch it back. Iterate.

### Week 24 — DSA in Swift
**Build:** Re-implement Swift's `Array`, `Dictionary`, and `Set` with Big-O analysis. Solve 20 LeetCode mediums.
**Study:** Swift collection performance characteristics, when COW bites you, hash collision handling.
**Drill:** Time yourself solving 5 LeetCode mediums in 45 minutes total.

### Week 25 — Resume, portfolio, network
**Build:** Rewrite your resume with new-CandyMan as the centerpiece — sig fig propagation, schema migration, Swift 6 strict concurrency, CloudKit sync, App Intents, modular SPM packages. Build a one-page portfolio site. Write a polished README for the GitHub repo (include the architecture diagram from week 9).
**Study:** how iOS hiring loops actually run at Apple / Meta / Google / Stripe / Airbnb. Read recent interview reports on Blind / Glassdoor (with skepticism).
**Drill:** DM five iOS engineers at target companies for a 20-minute coffee chat.

### Week 26 — Mock loops & apply
**Build:** Three mock interviews — one DSA, one system design, one iOS deep-dive. Use a paid coach (Interviewing.io or similar) for at least one.
**Study:** behavioral interview frameworks (STAR), salary negotiation basics (Patrick McKenzie's "Salary Negotiation").
**Drill:** Apply to 10 roles. Real ones, not "maybe."

**Phase 6 milestone:** new-CandyMan is live in the App Store. Resume + portfolio + active interview loops.

---

## The two parallel weekly tracks (every week, all 26)

### CS & Interview Prep · 3 hrs/wk
- 2 LeetCode problems in Swift (alternate easy/medium). Use NeetCode 150 as your spine.
- 1 mobile system design topic — read one chapter of *System Design Interview Vol. 2* (Alex Xu) or a top-tier eng blog post.
- 1 WWDC video — start with the current year, then dig into all-time greats (anything by Doug Gregor, Holly Borla, the SwiftUI team).

### Craft & Community · 2 hrs/wk
- 2 articles from Swift by Sundell, Point-Free, objc.io, Hacking with Swift, or Donny Wals.
- 1 polished commit to new-CandyMan with a PR-style description, even though you're solo. Practice the artifact of a great PR.
- 1 public learning post — tweet, Mastodon, or a quick blog post. Compounds.
- Monthly: read the source of one popular open-source iOS library (Alamofire, swift-composable-architecture, swift-collections, Nuke).

---

## What "top 1%" actually means (worth re-reading monthly)

There are roughly 500,000 active iOS developers worldwide. Top 1% = ~5,000 people. They share four traits:

1. **Depth in fundamentals.** They can re-derive how SwiftUI works, why ARC chose its rules, how the Swift runtime dispatches a protocol method. Not because they memorize trivia — because they were curious and went looking.
2. **Production scars.** They have shipped real apps, hit real bugs, and have opinions formed by pain. Your CandyMan launch in week 22 starts this clock.
3. **Communication.** They write clear docs, give clear code reviews, explain trade-offs to non-engineers. The weekly post is for this muscle.
4. **Compounding curiosity.** They watch WWDC every year, read source, are still surprised by Swift. Build the habit now — it's the only one that matters at year 5.

You'll have all four by week 26 if you do the work.

---

## Appendix A — SwiftUI vs UIKit decision matrix

| Situation | Use |
| --- | --- |
| New screen, standard layout | SwiftUI |
| Heavy infinite scroll (1000s of items, complex cells) | UIKit (`UICollectionView` with diffable data source) |
| Custom drawing, particles, real-time graphics | UIKit + Core Animation, or Metal |
| Custom input (e.g., CandyMan's numeric keypad) | UIKit, bridged via `UIViewRepresentable` |
| Anything that needs deep AppKit-style control | UIKit |
| Default | SwiftUI |

## Appendix B — Recommended books/courses

- *Hacking with Swift* by Paul Hudson (free, the best on-ramp)
- *Swift in Depth* by Tjeerd in 't Veen (intermediate language deep-dive)
- *Advanced Swift* by Chris Eidhof et al. (the language at the limits)
- *Thinking in SwiftUI* by objc.io (mental model book)
- Point-Free video series (advanced architecture; not cheap, worth it)
- WWDC video archive — free, irreplaceable

## Appendix C — Companies' iOS interview signal

- **Apple:** deep iOS, frameworks knowledge, debugging stories. Less DSA than peers.
- **Meta:** heavy DSA + system design. iOS knowledge expected but not the bar.
- **Google:** classic SWE loop with iOS specialization round.
- **Stripe / Airbnb / Lyft:** product sense, code quality, testing, real-world iOS.
- **Indie:** ship one app to 1,000 paying users. That's the only credential that matters.

## Appendix D — CandyMan feature → skill cross-reference

| Existing file | Phase | What rebuilding it teaches |
| --- | --- | --- |
| `Models.swift` | 1 (W1) | Enums, value types, protocol design |
| `BatchCalculator.swift` | 1 (W2) | Pure functions, numerical correctness, testability |
| `ShapePickerView.swift` | 2 (W4) | SwiftUI grids, navigation, SF Symbols |
| `ScalePickerSheet.swift`, `SyringePickerSheet.swift` | 2 (W5) | Sheets, animations, custom layouts |
| `MoldCalibrationView.swift` | 2 (W6) | Forms, validation, accessibility |
| ScribbleKiller / custom keypad | 2 (W7) | UIKit interop |
| `BatchConfigViewModel.swift` | 3 (W8) | MVVM, `@Observable`, environment injection |
| (project structure) | 3 (W9) | SPM modularization |
| `BatchRepository` (new) | 3 (W10) | async/await |
| `CrashReporter.swift` | 3 (W11) | Actors, Swift 6 concurrency |
| `SavedBatch.swift`, `BatchTemplate.swift` | 3 (W12) | SwiftData, schema migration |
| (CloudKit layer, new) | 4 (W13) | Cloud sync, conflict resolution |
| (Sign in with Apple, new) | 4 (W14) | Auth, Keychain |
| `SigFigs.swift` + tests | 4 (W15) | Swift Testing, property-based testing |
| `CandyManTests/` (rebuild) | 4 (W16) | UI tests, page objects, CI |
| `CrashReporter.swift` (replace) | 4 (W17) | Observability, structured logging |
| `BatchOutputView`, history | 5 (W18) | Performance profiling |
| (Widget + App Intent, new) | 5 (W19) | WidgetKit, App Intents |
| (Live Activity, new) | 5 (W20) | Notifications, BGTaskScheduler |
| (iPad/watch/vision, new) | 5 (W21) | Multi-platform |
| (App Store) | 6 (W22) | Shipping |
