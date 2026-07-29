# ChargeGlow Physical-Device Test Checklist

Do not mark an item passed without direct observation. Record screenshots,
screen recordings, timestamps, logs, and exact wording for every failure in
`docs/feasibility-report.md`.

## Test identity

- [ ] iPhone model recorded.
- [ ] Exact iOS version and build recorded.
- [ ] Dynamic Island availability recorded.
- [ ] Codemagic build number and commit SHA recorded.
- [ ] iLoader and SideStore versions recorded.
- [ ] ChargeGlow launched once after installation.
- [ ] Live Activities enabled for ChargeGlow in Settings.

## Artifact and installation

### Direct iLoader USB — primary

- [ ] IPA SHA-256 matches the Codemagic artifact.
- [ ] iLoader signs and installs the main application.
- [ ] iLoader signs and installs `ChargeGlowWidgets.appex`.
- [ ] ChargeGlow launches without a signing or trust error.
- [ ] Manual **Start Live Activity** displays the Lock Screen card.
- [ ] Manual activity appears in Dynamic Island.
- [ ] Manual **Stop** dismisses it.
- [ ] iLoader log saved.

### SideStore — secondary

- [ ] The same IPA imports successfully.
- [ ] ChargeGlow launches after SideStore re-signing.
- [ ] The embedded widget remains functional.
- [ ] Manual Start and Stop work.
- [ ] SideStore log or screenshots saved.

SideStore failure is non-blocking when the primary direct USB path works, but it
must be explained in the report.

## Shortcuts discovery and setup

- [ ] **Start Charging Theme** appears in Shortcuts.
- [ ] **Stop Charging Theme** appears in Shortcuts.
- [ ] Running Start manually in Shortcuts starts the activity without opening
      the app UI.
- [ ] Running Stop manually in Shortcuts ends it.
- [ ] Charger Connected automation created with Start.
- [ ] Charger Disconnected automation created with Stop.
- [ ] Both automations configured to run automatically where available.
- [ ] Screenshots of both automation configurations saved.

The application cannot inspect the automations, so screenshots and execution
results are the source of truth.

## Critical automatic flow

Run each case from a known stopped state.

| Case | Expected result | Pass |
| --- | --- | --- |
| Connect while unlocked | Start intent runs; exactly one activity appears | [ ] |
| Disconnect while unlocked | Stop intent runs; activity disappears | [ ] |
| Connect while locked | Activity appears without opening app UI | [ ] |
| Disconnect while locked | Activity ends without unlocking | [ ] |
| App in background | Connected/disconnected flow succeeds | [ ] |
| App suspended | Connected/disconnected flow succeeds | [ ] |
| Removed from app switcher | Outcome is observed and documented | [ ] |
| After iPhone restart | Outcome is observed and documented | [ ] |

For the locked test, capture a continuous screen recording from before charger
connection through activity presentation where possible.

## Data accuracy and presentation

- [ ] Lock Screen percentage equals the current system battery percentage at
      intent execution, allowing only an observed rounding difference.
- [ ] Charging state is `Charging` while connected.
- [ ] Full state appears only after a real 100%/full observation.
- [ ] Unavailable percentage displays `—`, never a fabricated number.
- [ ] Last-updated time is visible and accurate.
- [ ] Lock Screen Neon Orbit layout fits without clipping.
- [ ] Dynamic Island compact leading and trailing layouts fit.
- [ ] Dynamic Island minimal layout fits.
- [ ] Dynamic Island expanded layout fits.
- [ ] Apple's normal charging indication remains unchanged.

Do not fail the spike merely because the percentage stops updating after process
suspension; confirm that the displayed value remains the last real reading.

## Lifecycle and error cases

- [ ] Run Start twice: only one activity remains and the second call reports
      already running.
- [ ] Run Stop twice: the second call reports already stopped without failure.
- [ ] Reconnect rapidly: no duplicate activity remains.
- [ ] If multiple activities can be induced, reopening the app retains the
      newest and ends older duplicates.
- [ ] Disable Live Activities: Start returns a clear authorization message.
- [ ] Re-enable Live Activities: Start works again.
- [ ] Low Power Mode outcome recorded.
- [ ] Airplane Mode outcome recorded; no network should be required.
- [ ] Battery unavailable behavior recorded if it can be reproduced.
- [ ] Disconnect after reaching 100% ends the activity.

## Diagnostics evidence

- [ ] Export `diagnostics.json` after the normal flow.
- [ ] Export another copy after at least one error case.
- [ ] Save Codemagic test and device-build logs.
- [ ] Save iLoader logs.
- [ ] Record every diagnostic code shown in the UI.
- [ ] Verify logs contain no Apple Account, provisioning secret, or personal
      content.

## Gate classification

- [ ] **GO:** all critical locked automation and direct USB tests pass.
- [ ] **CONDITIONAL GO:** primary flow works but force-quit, reboot, or
      SideStore has a documented limitation requiring product fallback.
- [ ] **NO-GO:** intent discovery, locked automatic start/stop, Live Activity
      presentation, or both signing paths fail.
