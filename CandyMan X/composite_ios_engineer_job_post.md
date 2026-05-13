# 📱 Composite Entry-Level iOS Engineer — Job Posting
> **Methodology:** Synthesized from ~80–100 job listings scraped across Indeed, Glassdoor, Built In, ZipRecruiter, and SimplyHired (May 2026). Each skill/requirement below is ranked by approximate market frequency. Use this as a gap analysis and study roadmap.

---

## 🏢 About the Role

You will design, develop, test, and ship features for a native iOS application. You will work closely with product managers, designers, and backend engineers in an agile environment. You will write clean, maintainable Swift code, participate in code reviews, and take ownership of features from design through App Store deployment.

*This is a composite role — no single real posting contains all of this, but this represents what the market collectively demands from entry-to-junior iOS engineers in 2026.*

---

## 🧠 Required Technical Skills

### Tier 1 — Near-Universal (~90%+ of postings)
> If you don't have these, you won't clear the filter.

| Skill | Notes |
|---|---|
| **Swift** | The dominant language. Swift 5.9+ expected. Protocol-oriented and value-type thinking. |
| **Xcode** | Full mastery: debugger, Instruments, Simulator, scheme configuration, signing/provisioning. |
| **UIKit** | Still required in the majority of postings — many codebases are UIKit-first with SwiftUI additions. |
| **SwiftUI** | Rapidly closing the gap on UIKit. Declarative UI, state management (`@State`, `@Binding`, `@ObservableObject`). |
| **Git** | Version control is non-negotiable. Branching, PRs, rebasing, resolving conflicts. GitHub/GitLab assumed. |
| **RESTful APIs** | Consuming JSON APIs via `URLSession` or Alamofire. Understanding of HTTP methods, status codes, auth headers. |
| **MVC Architecture** | The historical default. You must understand it thoroughly even if you don't prefer it. |
| **MVVM Architecture** | The current industry-preferred pattern at most product companies. Understand separation of concerns. |

---

### Tier 2 — Very Common (~60–80% of postings)
> These separate candidates who get interviews from those who don't.

| Skill | Notes |
|---|---|
| **Core Data / SwiftData** | Local persistence layer. CRUD operations, relationships, migrations. SwiftData is the modern replacement. |
| **Combine / async-await** | Reactive and structured concurrency. `async`/`await` + `Task` is the modern standard; Combine still widely used for reactive chains. |
| **Unit Testing (XCTest)** | Writing testable code and unit tests. Most postings require familiarity with XCTest. |
| **Auto Layout / Programmatic Layouts** | Understanding of constraints, stack views. Many modern shops prefer programmatic UI over Storyboards. |
| **Networking & JSON Parsing** | `Codable`, `Decodable`, error handling in async contexts. |
| **App Store Submission** | TestFlight, provisioning profiles, certificates, app review process. At least 1 published app is a strong differentiator. |
| **Debugging & Instruments** | Memory graph, time profiler, Leaks tool. Performance awareness is increasingly expected even at entry level. |
| **Agile / Scrum** | Standups, sprint planning, Jira/Linear, estimation. Nearly all product companies operate this way. |

---

### Tier 3 — Common (~35–60% of postings)
> Important for differentiation. Strong candidates have at least 3–4 of these.

| Skill | Notes |
|---|---|
| **Objective-C** (read-only is fine) | Legacy codebases still exist. You won't write it from scratch, but you need to read and modify it. |
| **CI/CD** | GitHub Actions, Fastlane, Bitrise, or Xcode Cloud. Automating builds, tests, and deployments. |
| **Core Animation / Core Graphics** | Custom UI components, transitions, drawing. Differentiating in consumer app roles. |
| **Firebase** | Crashlytics for crash reporting, Analytics, Remote Config, Push Notifications (FCM). Extremely common in startups. |
| **Swift Package Manager (SPM)** | Modern dependency management. Largely replacing CocoaPods. |
| **CocoaPods** | Still widely used in older codebases. |
| **UI Testing (XCUITest)** | Less universal than unit tests but increasingly expected. |
| **Figma** | Reading design specs, extracting assets, using developer handoff. You're expected to bridge design ↔ code. |
| **Push Notifications (APNs)** | Remote and local notifications. Many production apps require this. |
| **SOLID Principles** | Single responsibility, open/closed, etc. Expect questions on these in interviews. |

---

### Tier 4 — Nice-to-Have / Differentiators (~15–35% of postings)
> These won't get you hired alone but signal a more experienced candidate.

| Skill | Notes |
|---|---|
| **Core Location / MapKit** | Used frequently in logistics, delivery, travel apps. |
| **HealthKit / WatchKit** | Health and fitness vertical — dominant in wearables-adjacent roles. |
| **ARKit / RealityKit** | Emerging; niche but growing. Strong differentiator for certain product companies. |
| **Core ML / CreateML** | On-device machine learning. Increasingly mentioned as AI features ship inside mobile apps. |
| **VIPER Architecture** | Used at larger engineering orgs. Understand conceptually; ability to navigate it is enough at entry level. |
| **CloudKit / iCloud** | Syncing user data across devices. Common in consumer apps. |
| **In-App Purchases / StoreKit** | Required for monetized consumer apps. RevenueCat is a common abstraction layer. |
| **GraphQL** | Backend integration for companies using it (Shopify ecosystem, etc.). |
| **Accessibility (a11y)** | VoiceOver, Dynamic Type, accessibility identifiers. Larger companies increasingly require this. |
| **AVFoundation** | Audio/video playback, recording. Required in media-heavy apps. |
| **WebSockets** | Real-time apps (chat, trading, live sports). Growing in demand. |
| **Snapshot Testing** | Used at companies with large design systems to prevent UI regressions. |

---

## 🛠 Toolchain Summary

```
Languages:     Swift (primary), Objective-C (legacy read)
UI:            SwiftUI + UIKit
IDE:           Xcode
Persistence:   Core Data / SwiftData / UserDefaults / Keychain
Networking:    URLSession / Alamofire / GraphQL
Concurrency:   async/await, Combine, GCD
Architecture:  MVC → MVVM (primary), VIPER (awareness)
Testing:       XCTest, XCUITest, Snapshot Testing
CI/CD:         GitHub Actions, Fastlane, Bitrise, Xcode Cloud
Dependencies:  Swift Package Manager, CocoaPods
Version Ctrl:  Git (GitHub / GitLab)
Design:        Figma (dev handoff mode)
Analytics:     Firebase, Instruments
```

---

## 📋 Responsibilities (Composite)

- Design and implement new features for the iOS application under guidance of senior engineers
- Write clean, modular, well-documented Swift code adherent to team standards
- Participate in code reviews and incorporate feedback constructively
- Write unit and integration tests for new and existing code
- Integrate with RESTful (and occasionally GraphQL) backend APIs
- Identify and resolve UI/UX and performance issues using Xcode Instruments
- Collaborate cross-functionally with product, design, QA, and backend engineering
- Participate in sprint ceremonies: standups, planning, retrospectives
- Contribute to App Store submission process including TestFlight distribution
- Stay current with Apple platform releases and WWDC announcements

---

## 🎓 Education & Experience Requirements

| Requirement | Frequency |
|---|---|
| B.S. in Computer Science, Software Engineering, or related technical field | ~70% of postings |
| "Equivalent practical experience" accepted in lieu of degree | ~55% of postings |
| 0–2 years of professional iOS experience | Entry-level band |
| At least 1 app published to the App Store | Strongly preferred (~50%) |
| Portfolio / GitHub with visible Swift projects | Implied by majority |

> **Note for non-CS degrees:** Your ChemE background + demonstrated iOS portfolio + published app is a highly credible substitute. Many postings list CS degree as preferred, not required, and hiring managers respond to shipped software.

---

## 💬 Soft Skills (Explicitly Stated Across Postings)

1. **Communication** — Written and verbal, across technical and non-technical stakeholders
2. **Collaboration** — Cross-functional comfort (design, backend, product, QA)
3. **Ownership mentality** — Takes problems through to resolution, doesn't drop the ball
4. **Curiosity / growth mindset** — Actively seeks feedback, iterates rapidly
5. **Self-direction** — Manages tasks and time without handholding in async environments
6. **Attention to detail** — UI fidelity, edge case coverage, crash-free code

---

## 💰 Compensation Benchmarks (U.S. Market, 2026)

| Level | Salary Range |
|---|---|
| Entry-Level (0–2 yrs) | $85,000 – $130,000 |
| Junior / SDE I (1–3 yrs) | $110,000 – $150,000 |
| Mid-Level (3–5 yrs) | $140,000 – $190,000 |
| Senior (5+ yrs) | $180,000 – $280,000+ |

> Ranges vary heavily by company type (FAANG vs. startup vs. enterprise), geography (SF/NYC vs. remote/SoCal), and equity structure. Defense/aerospace roles (Northrop, Anduril, AeroVironment) often skew toward the lower salary end but offer stability, clearance-building, and RSUs.

---

## 🗺 Your Gap Analysis Checklist

Use this to score yourself honestly.

### Must-Have (Tier 1)
- [ ] Swift — fluent (not just vibe-coded; can write it from scratch)
- [ ] Xcode — comfortable with full toolchain
- [ ] UIKit — can build layouts programmatically
- [ ] SwiftUI — building real features with proper state management
- [ ] Git — branching, PRs, rebasing
- [ ] REST API consumption — URLSession + Codable
- [ ] MVC + MVVM — understand and can implement both

### Should-Have (Tier 2)
- [ ] Core Data or SwiftData
- [ ] async/await concurrency
- [ ] Unit tests with XCTest
- [ ] At least 1 published or near-publishable App Store app
- [ ] Firebase (Crashlytics at minimum)
- [ ] Instruments for performance profiling

### Nice-to-Have (Tier 3–4)
- [ ] CI/CD pipeline (GitHub Actions + Fastlane)
- [ ] Objective-C (read-only)
- [ ] Figma → code workflow
- [ ] SPM dependency management
- [ ] SOLID principles (interview prep)
- [ ] Core Animation / custom UI

---

## 🎯 Strategic Takeaway

The **minimum viable candidate** for an entry-level iOS role in 2026 is:

> *Fluent Swift + UIKit/SwiftUI + MVVM + Git + RESTful APIs + XCTest + 1 shipped or portfolio-quality App Store app + clean GitHub*

The **differentiated candidate** adds:

> *Core Data/SwiftData + async/await + CI/CD awareness + Firebase + published app with real users + ability to read Objective-C + Figma handoff fluency*

CandyMan and your planned workout tracking app, once polished and on the App Store, directly address the #1 differentiator hiring managers cite: *shipped software that real users can download.*

---

*Last updated: May 2026 | Sources: Indeed, Glassdoor, Built In (National + LA + SF + NYC), ZipRecruiter, SimplyHired*
