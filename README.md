# ChargeGlow Phase 0/1 Feasibility Spike

ChargeGlow is an iOS 17+ feasibility build that tests whether a user-created
Shortcuts charger automation can start and stop an official Live Activity while
the iPhone is locked. It does not replace Apple's charging interface.

This repository intentionally contains only:

- one SwiftUI app screen;
- one Neon Orbit Live Activity;
- Lock Screen and basic Dynamic Island layouts;
- Start and Stop App Intents;
- approximate point-in-time readings from the public iOS battery API;
- duplicate recovery, diagnostics, and unit tests.

The full theme gallery, onboarding, purchases, backend, analytics, and production
polish are out of scope until the physical-device gate passes.

## Current status

**CONDITIONAL GO — Phase 0/1 physical-device feasibility is complete.**

Codemagic build/tests, direct iLoader installation, locked automatic Start/Stop,
Lock Screen, all Dynamic Island layouts, duplicate prevention, Outdated
presentation, and force-quit recovery passed on an iPhone 14 Pro running iOS
26.5.2. Start and Stop did not run in the tested after-reboot state before
ChargeGlow was opened; whether first unlock alone is sufficient remains
unisolated. Proceed to next-phase planning only with that documented limitation
and manual fallback accepted. See
[the feasibility report](docs/feasibility-report.md) for the evidence and final
decision.

## Requirements

- GitHub repository connected to Codemagic.
- Codemagic macOS builder with Xcode 26.4.1.
- iPhone with iOS 17 or later and Dynamic Island for the complete matrix.
- Developer Mode enabled on the iPhone.
- A free Apple Account for the agreed iLoader signing path.

No Apple certificate, password, API key, or provisioning profile belongs in this
repository.

## Build with Codemagic

1. Push the repository, including `codemagic.yaml`, to GitHub.
2. Add the repository as a Codemagic application.
3. Select the `chargeglow-feasibility` workflow.
4. Start a build.
5. Confirm that the Xcode verification, tests, unsigned device build, and payload
   verification steps all pass.
6. Download:
   - `ChargeGlow-Spike-unsigned.ipa`
   - its `.sha256` checksum;
   - test and device-build logs.
7. On Windows, verify the download:

   ```powershell
   Get-FileHash .\ChargeGlow-Spike-unsigned.ipa -Algorithm SHA256
   ```

   Compare the result with the downloaded checksum file.

The workflow deliberately builds without Apple credentials, verifies that
`ChargeGlowWidgets.appex` is embedded, and packages the result for local
re-signing.

## Install path A: iLoader over USB

Use only the official iLoader release you trust and review its security model
before entering an Apple Account.

1. Connect the unlocked iPhone to Windows by USB and trust the computer.
2. Enable Developer Mode on the iPhone.
3. Open iLoader and sign in using the Apple Account chosen for development.
4. Choose the direct IPA install action and select the unsigned ChargeGlow IPA.
5. Allow iLoader to create development signatures for both the main app and its
   embedded widget extension.
6. Trust the developer app in **Settings > General > VPN & Device Management**.
7. Launch ChargeGlow once before checking Shortcuts.

Record the iLoader version and export its log. A free development signature is
temporary and is not a production distribution method.

## Install path B: SideStore

Run this only after the direct USB test, so failures remain attributable.

1. Use iLoader to install and configure SideStore.
2. Import the same unsigned IPA into SideStore.
3. Confirm that ChargeGlow launches and that the widget extension remains
   embedded after re-signing.
4. Repeat the intent discovery and manual Live Activity smoke tests.

SideStore failure does not block the primary Go decision when direct USB
installation works; it must still be documented.

## Shortcuts charger automations

After launching ChargeGlow once:

1. Open Shortcuts and confirm **Start Charging Theme** and
   **Stop Charging Theme** appear under ChargeGlow actions.
2. Create a personal automation for **Charger > Is Connected**.
3. Add **Start Charging Theme** and configure the automation to run
   automatically without confirmation where iOS permits.
4. Create a second personal automation for **Charger > Is Disconnected**.
5. Add **Stop Charging Theme** with the equivalent automatic-run setting.

The app cannot create or inspect these personal automations. Setup status is
verified only by the physical tests.

## Test and evidence

Follow [the physical-device checklist](docs/physical-device-test-checklist.md)
and enter actual results in
[the feasibility report](docs/feasibility-report.md). Export
`diagnostics.json` from the app and retain Codemagic and iLoader logs.

## Known technical limitation

ChargeGlow reads the battery using public `UIDevice` APIs. The value exposed to
third-party apps can be coarser than the percentage shown in the status bar, so
the UI labels it with `≈` instead of claiming exact equality. ChargeGlow refreshes
on foreground activation, on system battery notifications, on manual refresh,
and once per minute while foregrounded. When iOS suspends the process, the Live
Activity marks its last value as outdated after two minutes; it never invents
intermediate percentages.

The tested charger automations also did not invoke ChargeGlow after an iPhone
reboot when the app had not been opened. The test did not isolate whether first
unlock alone is sufficient. Users must unlock once and may need to launch
ChargeGlow once, then reconnect the charger or use the manual action. The exact
iOS subsystem responsible cannot be diagnosed from app logs when the app
receives no execution time.

## Diagnostic timeline

The exported `diagnostics.json` records an ordered, bounded timeline of every
meaningful event that iOS delivers to ChargeGlow:

- App Intent invocation, battery capture, completion, and error.
- Activity recovery, start, skipped update, public API update, and end.
- Manual Start and Stop actions.
- Battery callbacks while the app has execution time.
- Foreground, inactive, and background scene transitions.

New records include a sequence number, process uptime, correlation ID, battery
snapshot, charging state, and active-activity count where applicable. iOS can
suspend the process while the phone is locked, so the absence of events during
that interval means the app had no execution time; ChargeGlow does not run a
continuous heartbeat or claim otherwise.

## Identifying the installed build

The app displays its version, bundle build number, Git commit, and Codemagic
build ID directly below the Neon Orbit heading. Codemagic stamps these values
before compilation and verifies the packaged app contains them. Every new
diagnostic event also includes the same identity fields.

The first instrumented timeline release was `1.1.0`. Release `1.1.1` adds an
opportunistic disconnect fallback: when iOS delivers a real disconnected
battery event while the app still has execution time, ChargeGlow immediately
ends any active charging activity. Release `1.2.0` makes the public battery
API's granularity and data freshness explicit and adds foreground polling. Its
bundle build number is the Codemagic workflow build number, allowing screenshots
and exported logs to identify the exact installed IPA.
