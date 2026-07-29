# Phase 0 Technical Assumptions

This is a historical record of the feasibility configuration preserved by the
`phase-1-conditional-go` tag. Phase 2 replaces the temporary bundle IDs with
`com.mohamedalaa.chargeglow` and `com.mohamedalaa.chargeglow.widgets`; see the
[Phase 2 Beta MVP plan](phase-2-beta-mvp-plan.md).

## Fixed decisions

| Area | Decision |
| --- | --- |
| Minimum OS | iOS 17.0 |
| Language | Swift 6 |
| CI toolchain | Codemagic Xcode 26.4.1 |
| App ID | `com.mohamedalaa.chargeglow.spike` |
| Widget ID | `com.mohamedalaa.chargeglow.spike.widgets` |
| Storage | App container only; no App Group |
| Network | None |
| Distribution | Unsigned Codemagic IPA, locally re-signed by iLoader |
| Theme | Fixed `neon-orbit` |
| Instrumented release | `1.2.0`; build number stamped from Codemagic |

## API assumptions to verify

1. `LiveActivityIntent` is discoverable through Shortcuts on the test OS.
2. A Charger personal automation can execute that intent automatically.
3. The intent process can call `Activity.request` while the app UI is closed.
4. Direct iLoader re-signing preserves and provisions the WidgetKit extension.
5. The activity appears on the Lock Screen and in Dynamic Island.
6. A second intent can enumerate and immediately end the activity.
7. `UIDevice` returns a usable battery value during the short intent execution
   window.
8. `Activity.activities` is sufficient for duplicate prevention and recovery
   without persisting an activity identifier.

Apple documents background Live Activity starts through `LiveActivityIntent`,
but the exact Charger automation and third-party re-signing chain is treated as
unverified until physical evidence exists.

## Honest update behavior

- Start captures the latest value exposed by the public `UIDevice` API.
- The public value may be coarser than and differ from the status-bar value, so
  ChargeGlow labels available percentages as approximate.
- Foreground battery notifications and a one-minute foreground poll can update
  an active activity.
- A Live Activity snapshot becomes visibly stale after two minutes without an
  update.
- Suspension can stop those updates at any time.
- No wattage, charging speed, battery health, temperature, or time-to-full is
  inferred.
- An unavailable battery value remains unavailable.

## Security and privacy

- No login exists inside ChargeGlow.
- No data leaves the device.
- Diagnostics are bounded local JSON plus OSLog entries.
- Diagnostics contain operation state and error codes, not Apple credentials or
  personal content.
- The ordered timeline correlates UI and Intent operations with ActivityKit
  actions and public iOS battery snapshots.
- Every event carries the app version, bundle build, Git commit, and Codemagic
  build ID so evidence cannot be confused between installed IPAs.
- There is no background heartbeat; a timeline gap while suspended is expected
  evidence that iOS did not provide execution time.
- iLoader and SideStore are external test tools and are not part of ChargeGlow.
