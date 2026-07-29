# ChargeGlow Feasibility Report

> **Status: Pending physical-device verification**
>
> No physical-device behavior in this document is currently claimed as passed.
> The full MVP remains gated.

## Build and device

| Field | Actual value |
| --- | --- |
| Commit SHA | TBD |
| Codemagic build number | TBD |
| Xcode version reported by CI | TBD; expected 26.4.1 |
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
| Codemagic unit-test log | TBD |
| Codemagic device-build log | TBD |
| IPA SHA-256 | TBD |
| iLoader log | TBD |
| SideStore log | TBD |
| `diagnostics.json` normal flow | TBD |
| `diagnostics.json` failure flow | TBD |
| Connected automation screenshot | TBD |
| Disconnected automation screenshot | TBD |
| Locked flow screen recording | TBD |
| Lock Screen screenshot | TBD |
| Dynamic Island screenshots | TBD |

## Procedure and results

Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`. Never infer a pass from a different
test state.

| ID | Test | Expected | Actual | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| F-01 | Codemagic build and unit tests | All targets compile and tests pass | TBD | NOT RUN | TBD |
| F-02 | Direct iLoader installation | App and widget are signed and installed | TBD | NOT RUN | TBD |
| F-03 | SideStore installation | App and widget remain functional | TBD | NOT RUN | TBD |
| F-04 | Intent discovery | Start and Stop appear in Shortcuts | TBD | NOT RUN | TBD |
| F-05 | Manual Start intent | Starts without presenting app UI | TBD | NOT RUN | TBD |
| F-06 | Connected automation, locked | Exactly one activity appears | TBD | NOT RUN | TBD |
| F-07 | Lock Screen layout | Neon Orbit card is readable and unclipped | TBD | NOT RUN | TBD |
| F-08 | Dynamic Island layouts | Compact, minimal, and expanded render | TBD | NOT RUN | TBD |
| F-09 | Real battery snapshot | Matches device value or displays unavailable | TBD | NOT RUN | TBD |
| F-10 | Disconnected automation, locked | Activity ends without unlocking | TBD | NOT RUN | TBD |
| F-11 | Duplicate Start | Second call does not create a duplicate | TBD | NOT RUN | TBD |
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

TBD.

### iLoader direct USB

TBD.

### SideStore

TBD.

### ChargeGlow diagnostics

TBD.

### Battery freshness

Record the start snapshot, the system battery value, the last update before
suspension, and whether the timestamp made staleness clear.

TBD.

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
