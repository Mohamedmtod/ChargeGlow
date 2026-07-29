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

- [ ] App and Live Activity prefix every available public API percentage with
      `≈`; record its difference from the status-bar percentage.
- [ ] Manual Start captures a new public API snapshot rather than reusing the
      previous on-screen timestamp.
- [ ] While foregrounded, diagnostics contain a `foreground poll` observation
      approximately once per minute.
- [ ] After two minutes without an ActivityKit update, the Lock Screen card
      clearly labels its reading as outdated.
- [ ] Charging state is `Charging` while connected.
- [ ] Full state appears only after a real 100%/full observation.
- [ ] Unavailable percentage displays `—`, never a fabricated number.
- [ ] Last-updated time is visible and accurate.
- [ ] Lock Screen Neon Orbit layout fits without clipping.
- [ ] Dynamic Island compact leading and trailing layouts fit.
- [ ] Dynamic Island minimal layout fits.
- [ ] Dynamic Island expanded layout fits.
- [ ] Apple's normal charging indication remains unchanged.

Do not claim exact equality with Apple's status-bar percentage. When the process
is suspended, confirm that the displayed value remains the last public API
reading and becomes visibly outdated.

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

## Phase 2 themes and localization

- [ ] Neon Orbit can be selected and persists after force quit.
- [ ] Aurora Pulse can be selected and persists after force quit.
- [ ] Ember Circuit can be selected and persists after force quit.
- [ ] Aqua Flux can be selected and persists after force quit.
- [ ] Plasma Core can be selected and persists after force quit.
- [ ] Lumen Bloom can be selected and persists after force quit.
- [ ] Changing the selection does not restyle an already-running activity.
- [ ] After Stop, the next Start uses the newly selected theme.
- [ ] Every theme fits the Lock Screen presentation without clipping.
- [ ] Every theme fits Dynamic Island compact, minimal, and expanded
      presentations.
- [ ] App theme motion is smooth and does not obscure the percentage.
- [ ] Reduce Motion disables ambient theme movement and selection scaling.
- [ ] On iOS 26, cards and controls use native Liquid Glass and react cleanly
      to touch without reducing text contrast.
- [ ] On iOS 17 through iOS 25, the material fallback remains legible and all
      controls remain usable.
- [ ] Lock Screen and Dynamic Island remain legible without depending on
      continuous animation.
- [ ] English selection updates the app, Lock Screen, and Dynamic Island.
- [ ] Arabic selection updates the app, Lock Screen, and Dynamic Island with
      correct RTL layout.
- [ ] System selection follows the iOS app language.

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
