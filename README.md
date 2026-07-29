# ChargeGlow Phase 0/1 Feasibility Spike

ChargeGlow is an iOS 17+ feasibility build that tests whether a user-created
Shortcuts charger automation can start and stop an official Live Activity while
the iPhone is locked. It does not replace Apple's charging interface.

This repository intentionally contains only:

- one SwiftUI app screen;
- one Neon Orbit Live Activity;
- Lock Screen and basic Dynamic Island layouts;
- Start and Stop App Intents;
- real point-in-time battery readings;
- duplicate recovery, diagnostics, and unit tests.

The full theme gallery, onboarding, purchases, backend, analytics, and production
polish are out of scope until the physical-device gate passes.

## Current status

**Pending physical-device verification. Do not start the full MVP yet.**

The source and CI workflow have been prepared on Windows, where Xcode is not
available. A successful Codemagic build and physical iPhone evidence are still
required before any Go/No-Go conclusion.

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

ChargeGlow reads the battery using public `UIDevice` APIs. It updates the Live
Activity only while iOS gives the app execution time. Once the process is
suspended, the last real reading and timestamp remain visible; the percentage is
never estimated.
