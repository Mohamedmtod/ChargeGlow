# ChargeGlow Feasibility Report

> **Status: Pending physical-device verification**
>
> The Codemagic build, direct iLoader installation, real battery snapshot, and
> Lock Screen presentation passed. Automatic locked start/stop and Dynamic
> Island evidence remain pending. The full MVP remains gated.

## Build and device

| Field | Actual value |
| --- | --- |
| Commit SHA | `034a6c8` |
| Codemagic build ID / index | `6a6990de1b3c5bfe2f350249` / `2` |
| Xcode version reported by CI | 26.4.1; exact-version guard passed |
| iPhone model | TBD |
| iOS version and build | TBD |
| Dynamic Island | TBD |
| Always-On Display | TBD |
| iLoader version | TBD |
| SideStore version | TBD |
| Apple Account type | Free development signing |

## Evidence index

Store evidence outside Git if it contains device identifiers, then place safe
relative links or artifact names here.

| Evidence | Location |
| --- | --- |
| Codemagic unit-test log | Build artifacts for ID `6a6990de1b3c5bfe2f350249` |
| Codemagic device-build log | Build artifacts for ID `6a6990de1b3c5bfe2f350249` |
| IPA SHA-256 | Downloaded build artifacts; local verification still required |
| iLoader log | Not supplied; successful install proven by app launch and embedded Live Activity rendering |
| SideStore log | TBD |
| `diagnostics.json` normal flow | User-supplied JSON, 2026-07-29 05:45 UTC |
| `diagnostics.json` failure flow | User-supplied duplicate-start JSON, 2026-07-29 05:49 UTC |
| Connected automation screenshot | TBD |
| Disconnected automation screenshot | TBD |
| Locked flow screen recording | TBD |
| Lock Screen screenshot | User-supplied screenshot, 2026-07-29 08:45 Africa/Cairo |
| Dynamic Island screenshots | TBD |

## Procedure and results

Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`. Never infer a pass from a different
test state.

| ID | Test | Expected | Actual | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| F-01 | Codemagic build and unit tests | All targets compile and tests pass | Workflow finished successfully in 2m 30s and published the unsigned IPA/app artifacts | PASS | Codemagic build `6a6990de1b3c5bfe2f350249` |
| F-02 | Direct iLoader installation | App and widget are signed and installed | App launched, Live Activities reported enabled, and the embedded widget rendered on the Lock Screen | PASS | App and Lock Screen screenshots |
| F-03 | SideStore installation | App and widget remain functional | TBD | NOT RUN | TBD |
| F-04 | Intent discovery | Start and Stop appear in Shortcuts | TBD | NOT RUN | TBD |
| F-05 | Manual Start intent | Starts without presenting app UI | TBD | NOT RUN | TBD |
| F-06 | Connected automation, locked | Exactly one activity appears | TBD | NOT RUN | TBD |
| F-07 | Lock Screen layout | Neon Orbit card is readable and unclipped | Neon Orbit rendered below the clock with percentage, state, and update time readable | PASS | Lock Screen screenshot at 08:45 |
| F-08 | Dynamic Island layouts | Compact, minimal, and expanded render | TBD | NOT RUN | TBD |
| F-09 | Real battery snapshot | Matches device value or displays unavailable | App captured 25% Charging at 08:45:08; activity started at 08:45:28 and displayed 25% with the matching update time | PASS | App screenshots, Lock Screen screenshot, diagnostics JSON |
| F-10 | Disconnected automation, locked | Activity ends without unlocking | TBD | NOT RUN | TBD |
| F-11 | Duplicate Start | Second call does not create a duplicate | Second Start was rejected with `CG-ACT-002` while activity `ED29FE58-64D3-43E7-9654-A1C068A7858B` remained active | PASS | Diagnostics event at `2026-07-29T05:49:27Z` |
| F-12 | Idempotent Stop | Second call reports already stopped | TBD | NOT RUN | TBD |
| F-13 | Background/suspended process | Automatic flow behavior recorded | TBD | NOT RUN | TBD |
| F-14 | Removed from app switcher | Automatic flow behavior recorded | TBD | NOT RUN | TBD |
| F-15 | After iPhone restart | Automatic flow behavior recorded | TBD | NOT RUN | TBD |
| F-16 | Live Activities disabled | Clear authorization error returned | TBD | NOT RUN | TBD |
| F-17 | Rapid reconnect | No duplicate remains | TBD | NOT RUN | TBD |
| F-18 | Low Power Mode | Outcome recorded without fabricated data | TBD | NOT RUN | TBD |
| F-19 | 100% observation | Full shown only after real full state | TBD | NOT RUN | TBD |

## Logs and observations

### Codemagic

Build index 2 completed successfully from `main` at commit `034a6c8`. The
workflow published `ChargeGlow-Spike-unsigned.ipa`, `ChargeGlow.app.zip`, and
the combined artifacts archive. This proves the compile/unit-test/unsigned
packaging gate only; it does not prove installation or runtime behavior.

### iLoader direct USB

The app launched successfully after local signing. Live Activities authorization
reported Enabled, and the widget extension rendered a real Live Activity on the
Lock Screen. This proves the direct signing path preserved both bundles. The
exact iLoader version and raw iLoader log remain to be recorded.

### SideStore

TBD.

### ChargeGlow diagnostics

The supplied local diagnostics recorded:

- app launch at `2026-07-29T05:45:08Z`;
- Live Activity `ED29FE58-64D3-43E7-9654-A1C068A7858B` started at
  `2026-07-29T05:45:28Z`;
- a second Start was rejected with `CG-ACT-002` at
  `2026-07-29T05:49:27Z`, proving duplicate prevention.

### Battery freshness

Record the start snapshot, the system battery value, the last update before
suspension, and whether the timestamp made staleness clear.

The app and Live Activity displayed the real 25% charging snapshot with an
08:45 update time. The later Lock Screen status bar showed 24% while the Live
Activity intentionally retained 25%. This confirms that the activity preserves
the last real value rather than estimating background progress, and that the
timestamp communicates its age.

## Limitations discovered

| Limitation | State affected | User impact | Honest fallback |
| --- | --- | --- | --- |
| Continuous battery execution is not guaranteed | Suspended/background | Percentage may remain at last real value | Display last-updated time; never estimate |
| Free signing is temporary | Installation | Build eventually expires | Re-sign for testing; paid distribution later |
| Automation configuration cannot be read by the app | Setup | App cannot prove setup is correct | User checklist plus test action |
| Additional findings | TBD | TBD | TBD |

## Decision

### Classification

**PENDING — the physical-device gate has not been run.**

### Decision rules

- **GO:** direct USB installation works; both intents are discoverable; connected
  and disconnected automations start and stop exactly one activity while locked;
  Lock Screen and Dynamic Island render; battery data is real or explicitly
  unavailable.
- **CONDITIONAL GO:** the primary path passes, but force-quit, reboot, or
  SideStore has a documented limitation that can be handled by honest copy and a
  manual fallback.
- **NO-GO:** the intents are unavailable, locked automatic start/stop fails, the
  activity cannot render, or neither agreed installation path preserves the
  widget extension.

### Current recommendation

**Do not begin the full MVP.** Update this section only after all critical tests
have actual evidence.
