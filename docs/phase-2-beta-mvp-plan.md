# ChargeGlow — Phase 2 Beta MVP Plan

## Status

**Confirmed — M0 decisions recorded.** Phase 0/1 closed with a
`CONDITIONAL GO`. Phase 2 turns the
validated spike into a coherent beta product while preserving the proven
ActivityKit and Shortcuts path.

M0 completed on 2026-07-29: the Phase 1 tag was published, production bundle
IDs were applied, languages were confirmed, and the current versus intended
distribution paths were fixed.

M1 completed on 2026-07-29. Codemagic, the production-ID iLoader build,
System/English/Arabic switching, RTL/LTR, and synchronized app/Live Activity
language behavior passed on the physical test device.

M2 implementation is in progress. The current candidate adds the six-theme
catalog, persistent selection, unknown-theme fallback, Home gallery previews,
distinct app-only ambient motion with Reduce Motion support, and selected-theme
propagation into the next Live Activity without changing an already-running
activity. Lock Screen and Dynamic Island render deterministic theme states
without relying on continuous animation. The app uses native interactive
Liquid Glass for custom surfaces and controls on iOS 26, with an
`ultraThinMaterial`-based fallback that preserves the iOS 17 deployment target.

Phase 2 can proceed through the existing Codemagic + iLoader engineering path
without Apple Developer Program enrollment. It prepares a separate TestFlight
workflow, but that workflow is not a required gate until enrollment is
available. The intended public Beta path is TestFlight. Phase 2 does not include
a public App Store launch or monetization.

## Product contract

ChargeGlow lets a person select a visual charging theme and use personal
Shortcuts charger automations to start and stop a Live Activity. It is not a
replacement for Apple's charging interface and does not claim exact battery
telemetry.

The product must always communicate that:

- the percentage comes from the public iOS battery API and is approximate;
- the last real reading can become outdated while iOS suspends the app;
- ChargeGlow cannot create or inspect personal automations;
- after reboot, the user must unlock once and may need to launch ChargeGlow
  before relying on charger automations;
- no wattage, charging speed, temperature, health, or time-to-full is inferred.

## Confirmed product decisions

These decisions were confirmed on 2026-07-29.

| Decision | Confirmed value | Implementation consequence |
| --- | --- | --- |
| Public name | `ChargeGlow` | Remove all Spike wording before beta |
| App bundle ID | `com.mohamedalaa.chargeglow` | Creates a new installed app identity |
| Widget bundle ID | `com.mohamedalaa.chargeglow.widgets` | Must be signed with the final app |
| Minimum OS | iOS 17.0 | Preserves the validated compatibility target |
| Languages | English source plus Arabic, with full RTL | Use String Catalogs and eliminate hard-coded user-facing strings |
| Beta themes | 6 free local themes | Enough variety to validate selection and repeated use without a store |
| Theme set | Neon Orbit, Aurora Pulse, Ember Circuit, Aqua Flux, Plasma Core, Lumen Bloom | Distinct visual choices using shapes and gradients |
| Current distribution | Codemagic unsigned IPA + iLoader | Must not block implementation on enrollment |
| Intended public Beta | TestFlight after paid enrollment | Prepare but do not require its workflow yet |
| Monetization | Deferred to Phase 3 | First validate setup completion and repeated use |
| Backend | None | Theme selection and entitlements do not need a server in this phase |
| Analytics | No third-party SDK | Keeps the privacy surface small during beta |

The Phase 1 source state is preserved by the annotated
`phase-1-conditional-go` Git tag at commit `a926467`. Changing bundle IDs creates
a new installed app identity, so existing Shortcuts automations that reference
the Spike build must be recreated once after installing the first production-ID
build.

## In scope

- production app identity and removal of feasibility-only copy;
- Home, Themes, Setup, and Settings/Diagnostics experiences;
- a compiled local catalog with six themes;
- persistent selected-theme preference;
- Start intent using the selected theme without adding a required Shortcuts
  parameter;
- consistent Lock Screen and Dynamic Island rendering for every theme;
- honest approximate/unavailable/outdated battery presentation;
- first-run Shortcuts setup walkthrough and test actions;
- String Catalog localization with English as the development language;
- Arabic localization and full RTL verification, with no hard-coded
  user-facing strings;
- accessibility labels, Dynamic Type, Reduce Motion, contrast, and VoiceOver;
- local bounded diagnostics with an explicit clear action;
- preserved unsigned development artifacts plus a separate, optional signed
  TestFlight workflow with no signing credentials in Git;
- unit, UI, simulator-layout, and physical-device regression testing.

## Explicitly out of scope

- backend, accounts, cloud sync, remote theme downloads, or push updates;
- continuous background battery polling;
- wattage, charging speed, temperature, health, or time-to-full estimates;
- user-created themes or a full visual editor;
- subscriptions, paywalls, or paid theme packs;
- third-party analytics, ads, social features, or notifications;
- Android, iPad-specific product work, watchOS, macOS, and CarPlay customization;
- claiming that ChargeGlow can automatically configure Shortcuts.

## Technical direction

### Theme model

Add a small, versioned theme domain:

- `ThemeID`: stable `Codable`, `Hashable`, `Sendable` identifier;
- `ThemeDescriptor`: localized name, summary, preview colors, availability, and
  sort order;
- `ThemeCatalog`: compile-time list and safe fallback to Neon Orbit;
- `SelectedThemeStore`: protocol plus a `UserDefaults` implementation;
- `ChargingThemeRenderer`: a SwiftUI `@ViewBuilder` switch keyed by `ThemeID`.

The selected theme is read by `StartChargingThemeIntent` and copied into
`ChargingActivityAttributes.themeID`. An activity keeps the theme it started
with even if the person changes the selection later.

Do not add an App Group in Phase 2. The intent can read the app preference, and
the widget receives the immutable theme ID through ActivityKit attributes.
Reconsider App Groups only if a later widget or extension truly needs shared
mutable data.

### Activity engine

Keep `ChargingActivityManager` as an actor and preserve `Activity.activities` as
the source of truth. Refactor only behind testable boundaries:

- inject a battery snapshot provider;
- isolate activity planning from ActivityKit side effects;
- keep duplicate recovery and idempotent end behavior;
- observe ActivityKit authorization changes instead of checking only on refresh;
- register/update App Shortcut parameters during app initialization;
- retain the two-minute stale date and last real timestamp;
- use the chosen theme ID instead of the hard-coded `neon-orbit`.

The default Start shortcut continues to have no required theme parameter. The
person changes the theme in ChargeGlow, while the existing Charger automation
remains valid. A parameterized “Start Specific Theme” intent can be considered
after beta only.

### App structure

Use feature folders without introducing unnecessary frameworks:

```text
ChargeGlow/
  App/
  Features/
    Home/
    Themes/
    Setup/
    Settings/
  Core/
    Activity/
    Battery/
    Diagnostics/
    Preferences/
  Shared/
    Models/
    ThemeKit/
    Localization/
```

Shared ActivityKit models and theme renderers can continue using app/widget
target membership. Extract a local Swift package only if compile-time coupling
or testability becomes a real problem.

### Primary navigation

- **Home:** selected-theme preview, Live Activities authorization, current
  activity state, approximate snapshot, Start, Stop, and Refresh.
- **Themes:** six previews, selection, and full Lock Screen/Dynamic Island
  presentation examples.
- **Setup:** honest step-by-step Connected and Disconnected automation
  instructions, test Start/Stop, troubleshooting, and reboot warning.
- **Settings:** language/system setting, battery-data explanation, diagnostics
  export/clear, privacy, version/build identity, and support information.

The app may show completion checkmarks for steps the user explicitly confirms.
It must not claim it has detected a personal automation because iOS does not
provide that inspection API.

### Live Activity interaction

All themes must support Lock Screen, compact, minimal, and expanded
presentations. Keep the most important information glanceable:

- approximate percentage or unavailable mark;
- charging/disconnected/full state;
- last-updated or Outdated indication;
- theme identity without promotional content.

Evaluate one Stop button in the Lock Screen/expanded presentation as a manual
fallback. Ship it only if device testing confirms clear accessibility,
idempotency, and no regression to automatic Stop.

### Diagnostics and privacy

- retain bounded JSONL/JSON export and OSLog;
- add a visible “Clear diagnostics” action;
- avoid device serials, account identifiers, file paths, and Shortcuts content;
- keep build identity, correlation ID, sequence, uptime, activity count, and
  public battery snapshot;
- add a privacy policy stating exactly what is and is not collected;
- keep diagnostics local unless the user explicitly shares them.

## Delivery milestones

### M0 — Product identity and beta prerequisites

Deliver:

- approve final app name, bundle IDs, languages, and three theme names;
- decide individual versus organization Apple Developer enrollment;
- preserve the spike with a `phase-1-conditional-go` Git tag;
- document that old `.spike` automations must be recreated.

Exit gate:

- final identifiers are confirmed and available;
- distribution owner and signing approach are known;
- the reboot and approximate-battery constraints are accepted.

### M1 — Production foundation

Deliver:

- apply final identity and remove Spike/feasibility UI copy;
- organize features and core services;
- add preferences abstraction and migrations/versioning;
- register App Shortcuts during app initialization;
- keep existing unit tests green and add mocks for battery/activity boundaries;
- retain the current unsigned Codemagic workflow.

Exit gate:

- app, widget, and tests build under Xcode 26.4.1;
- unsigned IPA still contains `ChargeGlowWidgets.appex`;
- the original Neon Orbit locked automation regression passes.

### M2 — Theme system and gallery

Deliver:

- implement `ThemeID`, catalog, preference store, and renderer;
- implement Neon Orbit, Aurora Pulse, Ember Circuit, Aqua Flux, Plasma Core,
  and Lumen Bloom;
- add gallery previews and selection;
- propagate the selected theme through the Start intent into ActivityKit;
- add safe fallback for unknown or removed theme IDs.

Exit gate:

- each theme renders in Home, Lock Screen, compact, minimal, and expanded;
- changing selection affects the next activity but not the current activity;
- force quit does not lose selection;
- unknown IDs render Neon Orbit without a crash.

### M3 — Setup and user education

Deliver:

- first-run explanation of capabilities and battery limitations;
- Connected and Disconnected automation instructions;
- manual Start/Stop verification actions;
- troubleshooting for missing intents, disabled Live Activities, stale
  automations after reinstall, and post-reboot behavior;
- String Catalogs for every user-facing string in the app, widget, and intents;
- English source copy and Arabic translations;
- full RTL verification for Home, Themes, Setup, Settings, Lock Screen, and all
  Dynamic Island presentations.

Exit gate:

- a new tester can complete setup without developer assistance;
- the app never claims to detect an automation it cannot inspect;
- all limitation copy is readable with Dynamic Type and VoiceOver.

### M4 — Reliability and product polish

Deliver:

- authorization update observation;
- lifecycle recovery on launch/foreground and intent invocation;
- optional interactive Stop feasibility;
- clear diagnostics and privacy surfaces;
- error states for authorization, unavailable battery, duplicate Start, and
  already-stopped Stop;
- visual polish without continuous animation.

Exit gate:

- no duplicate survives rapid reconnect or repeated Start;
- repeated Stop remains idempotent;
- approximate, unavailable, full, and Outdated states are honest;
- the force-quit flow still passes;
- post-reboot behavior is characterized as first-unlock or first-launch and the
  matching fallback is shown.

### M5 — Engineering beta and TestFlight readiness

Deliver:

- a verified unsigned Codemagic + iLoader engineering build;
- a separate Codemagic signed archive/TestFlight workflow using environment
  groups and no credentials in Git; it remains optional until enrollment;
- a draft App Store metadata package, privacy URL, support URL, beta
  description, and review notes explaining Shortcuts setup; creating the actual
  App Store Connect record waits for enrollment;
- iLoader installation on at least one Dynamic Island device and one
  non-Dynamic Island device where available;
- preserved unsigned iLoader workflow for engineering diagnostics.

Exit gate:

- iLoader installs both app and widget using the production bundle IDs;
- intents appear after a clean install;
- selected theme starts/stops automatically while locked;
- all critical matrix rows below pass or have an accepted documented fallback;
- when paid enrollment becomes available, the TestFlight workflow must install
  both app and widget before the public Beta.

## Test matrix

### Automated

- battery normalization, unavailable values, state mapping, and stale date;
- catalog uniqueness, theme fallback, selection persistence, and migration;
- duplicate prevention, recovery ordering, multiple stale activities, and
  idempotent Stop;
- intent dialog/error mapping and selected-theme propagation;
- localization keys present in English and Arabic;
- SwiftUI smoke tests or snapshots for every theme/presentation where the CI
  toolchain supports them;
- IPA validation for bundle IDs, entitlements, version identity, and embedded
  widget.

### Physical device

- manual and automatic Start/Stop, unlocked and locked;
- foreground, background, suspension, and force quit;
- reboot before first unlock, after first unlock without opening the app, and
  after first app launch;
- Start twice, Stop twice, and rapid reconnect cycles;
- Live Activities disabled/re-enabled;
- approximate percentage, unavailable value if reproducible, Outdated, 100%,
  Low Power Mode, and Always-On Display;
- compact, minimal, expanded, Lock Screen, RTL, VoiceOver, and large Dynamic
  Type;
- clean install, update install, automation recreation after bundle-ID change,
  and TestFlight expiration/update behavior.

## Phase 2 release gate

The beta candidate is ready only when:

1. The unsigned Codemagic artifact is re-signed by iLoader and installs both the
   app and widget extension with the production bundle IDs.
2. A clean-install user can complete setup and see both intents.
3. Connected and Disconnected automations operate exactly one Live Activity
   while locked.
4. All six themes render legibly in every required presentation.
5. Approximate and stale readings are always labeled honestly.
6. Duplicate Start and repeated Stop remain safe.
7. Force-quit behavior passes.
8. The exact post-reboot boundary is documented and the app presents the
   correct fallback.
9. English, Arabic/RTL, VoiceOver, and Dynamic Type checks pass.
10. No credentials or personal diagnostic evidence exists in Git.
11. The separate TestFlight workflow is present and documented; passing it is
    deferred until paid Apple Developer enrollment.

## Phase 3, only after beta evidence

Use beta feedback to decide whether to add monetization and a larger gallery.
For a fixed collection of premium themes, prefer a non-consumable StoreKit 2
purchase with Restore Purchases. Use a subscription only if ChargeGlow commits
to ongoing, substantive value such as regular new theme releases or a service.

Possible later work:

- premium theme pack and StoreKit testing;
- additional local themes;
- optional iCloud preference sync;
- App Store production workflow and submission;
- anonymous first-party metrics only if a real product question justifies the
  privacy cost.

## Apple references

- [ActivityKit](https://developer.apple.com/documentation/activitykit/)
- [Displaying live data with Live Activities](https://developer.apple.com/documentation/ActivityKit/displaying-live-data-with-live-activities)
- [Live Activities design guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts)
- [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [StoreKit 2](https://developer.apple.com/storekit/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
