# ChargeGlow Feasibility Report

> **Status: CONDITIONAL GO — physical-device feasibility gate completed**
>
> The Codemagic build, direct iLoader installation, public battery capture,
> Lock Screen and Dynamic Island presentation, locked automatic Start/Stop,
> duplicate prevention, repeated Stop, Outdated presentation, and force-quit
> recovery passed. Start and Stop did not run after a reboot before ChargeGlow
> was opened; whether first unlock alone is sufficient remains unisolated. The
> primary concept is feasible, with that reboot
> limitation and the public battery API's approximate value explicitly accepted.

## Build and device

| Field | Actual value |
| --- | --- |
| Commit SHA | `034a6c8` |
| Codemagic build ID / index | `6a6990de1b3c5bfe2f350249` / `2` |
| Xcode version reported by CI | 26.4.1; exact-version guard passed |
| Latest installed test build | `1.2.0 (7)`, commit `c31c2409`, CI `6a6a1163c5b6cb2224bd54ff` |
| Disconnect fallback | Verified on device; ended the activity before the Stop intent completed |
| Battery freshness | Approximate marker and two-minute Outdated presentation verified in `1.2.0` |
| iPhone model | iPhone 14 Pro |
| iOS version and build | iOS 26.5.2; OS build number not supplied |
| Dynamic Island | Available; compact, minimal, and expanded presentations verified |
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
| `diagnostics.json` normal flow | User-supplied locked automatic Start/Stop timeline, build 7, sequences 197–211 |
| `diagnostics.json` failure flow | User-supplied duplicate-start and earlier background-disconnect timelines |
| `diagnostics.json` resilience flow | User-supplied build 7 timeline through sequence 329; force-quit flow passed, with no post-reboot intent invocation recorded for the failed run |
| Connected automation screenshot | TBD |
| Disconnected automation screenshot | TBD |
| Locked flow screen recording | TBD |
| Lock Screen screenshot | User-supplied screenshot, 2026-07-29 08:45 Africa/Cairo |
| Dynamic Island screenshots | User-supplied compact, minimal, and expanded screenshots from build 7 |
| Outdated screenshot | User-supplied Lock Screen screenshot showing `≈55%`, `Disconnected`, and `Outdated · Updated 6:30 PM` |

## Procedure and results

Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`. Never infer a pass from a different
test state.

| ID | Test | Expected | Actual | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| F-01 | Codemagic build and unit tests | All targets compile and tests pass | Workflow finished successfully in 2m 30s and published the unsigned IPA/app artifacts | PASS | Codemagic build `6a6990de1b3c5bfe2f350249` |
| F-02 | Direct iLoader installation | App and widget are signed and installed | App launched, Live Activities reported enabled, and the embedded widget rendered on the Lock Screen | PASS | App and Lock Screen screenshots |
| F-03 | SideStore installation | App and widget remain functional | TBD | NOT RUN | TBD |
| F-04 | Intent discovery | Start and Stop appear in Shortcuts | Both actions were selected and invoked from Shortcuts | PASS | Build 7 intent timelines |
| F-05 | Manual Start intent | Starts without presenting app UI | Start intent invoked at sequence 137 and completed with activity `32DB9B72-6098-45AF-BFCA-F2CCD9CB9D63` at sequence 142 without a foreground transition | PASS | Build 7 sequences 137–142 |
| F-06 | Connected automation, locked | Exactly one activity appears | User observed the activity appear while locked; automatic Start completed with activity `274EC9C2-321C-4D5E-B5E4-4FE1B93F6B36` | PASS | User observation and build 7 sequence 197 |
| F-07 | Lock Screen layout | Neon Orbit card is readable and unclipped | Neon Orbit rendered below the clock with percentage, state, and update time readable | PASS | Lock Screen screenshot at 08:45 |
| F-08 | Dynamic Island layouts | Compact, minimal, and expanded render | All three presentations rendered legibly with the approximate percentage and charging state | PASS | User-supplied build 7 screenshots |
| F-09 | Battery API snapshot | Public value and freshness are represented honestly | Build 7 displays the public value with `≈`; after updates ceased, the Lock Screen card visibly showed `Outdated` and retained its last-updated time | PASS | Build 7 app and Outdated Lock Screen screenshots |
| F-10 | Disconnected automation, locked | Activity ends without unlocking | Disconnect fallback ended the activity at sequences 199–201; Stop automation then invoked its intent at 203 and completed idempotently at 206, all before foreground sequence 207 | PASS | Build 7 sequences 198–207 and user locked-device observation |
| F-11 | Duplicate Start | Second call does not create a duplicate | Second Start was rejected with `CG-ACT-002` while activity `ED29FE58-64D3-43E7-9654-A1C068A7858B` remained active | PASS | Diagnostics event at `2026-07-29T05:49:27Z` |
| F-12 | Idempotent Stop | Second call reports already stopped | Stop intent completed with `nothing to end` after fallback, and the user separately confirmed that running Stop twice succeeds | PASS | Build 7 sequences 203–206 and direct user observation |
| F-13 | Background/suspended process | Automatic flow behavior recorded | Locked Start/Stop passed, and a suspended activity retained its last real value with a visible Outdated label | PASS | Build 7 sequences 197–207 and Outdated screenshot |
| F-14 | Removed from app switcher | Automatic flow behavior recorded | Start and Stop both passed after force quit/removal from the app switcher | PASS | Direct device observation and build 7 resilience diagnostics |
| F-15 | After iPhone restart | Automatic flow behavior recorded | Without opening ChargeGlow after reboot, Start and Stop both failed. The exported timeline contains no corresponding intent execution; first unlock versus first app launch was not isolated | FAIL | Direct device observation and build 7 resilience diagnostics |
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

A later detailed timeline recorded manual activity
`5A20AD9B-1BE1-4788-B7CE-6214C7F79033`:

- manual Start succeeded at sequence 9;
- the app entered background at sequence 12;
- a real disconnected snapshot arrived at sequence 13;
- the activity was updated to disconnected at sequence 15 but remained active;
- a real charging snapshot arrived after reconnect at sequence 17;
- no `intents` category event appeared anywhere in the timeline;
- manual Stop ended the activity at sequences 28–29.

This isolates the failure to Shortcuts automation invocation/configuration for
that run, not ActivityKit start, update, end, battery observation, or recovery.
The timeline also lacks the build-identity fields introduced in commit
`cc6b9e4`, proving that the latest IPA was not installed for this run.

A subsequent identity-stamped run verified installation of `1.1.0 (4)`, commit
`0653b955`, Codemagic build `6a6998ec30fa0c89d6227d3a`. In that run:

- manual Start created an activity at sequences 59–61;
- the app entered background at sequences 63–64;
- disconnect/reconnect callbacks arrived at sequences 65, 69, and 73 while the
  activity remained active;
- a second manual activity received additional disconnect/reconnect callbacks
  at sequences 97, 101, 105, and 109;
- the exported file contained no `intents` category in 65 new-build events;
- manual Stop remained reliable at sequences 88–89 and 115–116.

This independently confirms that build identity works and that the remaining
automatic-stop failure is outside the implemented App Intent handler. Release
`1.1.1` adds an opportunistic public-API fallback that ends an active activity
when one of these real disconnected callbacks reaches the running app process.

A current `1.2.0 (7)` run then verified the intended Shortcuts path:

- manual Shortcuts Start invoked at sequence 137, captured 50% at sequence 139,
  created an activity at sequence 141, and completed at sequence 142 without a
  foreground transition;
- a subsequent locked Charger Connected automation completed Start for activity
  `274EC9C2-321C-4D5E-B5E4-4FE1B93F6B36` at sequence 197;
- disconnection arrived at sequence 198 and the in-process fallback ended the
  activity at sequences 199–201;
- Stop automation independently invoked the Stop intent at sequence 203,
  captured the disconnected snapshot at 204, and completed idempotently with
  nothing left to end at sequences 205–206;
- the app did not return to foreground until sequences 207–209.

The fallback/Stop ordering is a benign race: both paths target the same
idempotent end operation, exactly one activity was removed, and the Stop intent
reported the already-ended state without ambiguity. This is direct evidence
that the critical locked automatic Start/Stop path works on the tested build.

### Battery freshness

Record the start snapshot, the system battery value, the last update before
suspension, and whether the timestamp made staleness clear.

The identity-stamped build recorded a public `UIDevice` reading of 10% at
13:36:05 and created the activity with 10% at 13:36:13. After the app entered
background, no percentage callback arrived for almost seven minutes. On
foreground activation at 13:43:05, the public API jumped directly to 15% and
the activity update completed. Device screenshots during this period showed
13% and later 17% in the status bar, confirming that the third-party public API
value is coarser than and not identical to Apple's status-bar value on this
device.

Release `1.2.0` therefore labels public API percentages with `≈`, refreshes on
foreground activation and once per foreground minute, captures again at manual
Start, and sets a two-minute ActivityKit stale date. Physical verification
confirmed both the approximate marker and the visible Outdated state while
preserving the last real reading and timestamp.

### Force-quit and reboot resilience

The user confirmed that both automatic Start and automatic Stop pass after
ChargeGlow is force-quit. The supplied build 7 timeline also contains subsequent
background intent invocations, activity creation, and idempotent end behavior
without requiring a foreground scene transition.

After an iPhone reboot, with ChargeGlow not opened, both Start and Stop failed.
No matching post-reboot intent invocation exists in the exported diagnostics.
This proves the tested reboot scenario fails, but the run did not isolate
whether the first device unlock alone would restore execution or whether
ChargeGlow must be launched once. The log also cannot prove which iOS subsystem
withheld execution because ChargeGlow received no execution time to instrument
it.

The most plausible explanation is iOS's Before First Unlock state: protected
app files and credentials are unavailable until the user unlocks once after a
restart. This is recorded as an inference from the observed reboot-only failure,
not as a documented guarantee that Shortcuts charger automations always behave
this way. The product fallback is to tell the user to unlock once after reboot
and, if needed, launch ChargeGlow once, then reconnect the charger or run Start
manually.

## Limitations discovered

| Limitation | State affected | User impact | Honest fallback |
| --- | --- | --- | --- |
| Continuous battery execution is not guaranteed | Suspended/background | Percentage may remain at last public API value | Display last-updated time and stale state; never estimate |
| Public `UIDevice` percentage differs from status bar | All battery displays | A rounded/coarse value can appear numerically inconsistent | Mark it approximate, show freshness, and never claim status-bar equality |
| Free signing is temporary | Installation | Build eventually expires | Re-sign for testing; paid distribution later |
| Automation configuration cannot be read by the app | Setup | App cannot prove setup is correct | User checklist plus test action |
| Automations can retain stale actions after reinstall | Charger automations | Earlier runs delivered battery callbacks but no App Intent | Recreate the automations or run the newly selected shortcuts; build 7 verified both intents after recreation |
| Post-reboot path failed on the tested device | After reboot without opening ChargeGlow | Charger automation did not invoke Start or Stop; first unlock versus first app launch is not yet isolated | Unlock once, open ChargeGlow if needed, then reconnect the charger or use the manual action |

## Decision

### Classification

**CONDITIONAL GO.** The primary USB-installed, locked-device automation path is
feasible and all critical UI, duplicate, freshness, and force-quit checks
passed. The tested post-reboot, before-first-app-launch path failed and requires
an explicit user-facing fallback.

### Decision rules

- **GO:** direct USB installation works; both intents are discoverable; connected
  and disconnected automations start and stop exactly one activity while locked;
  Lock Screen and Dynamic Island render; battery data is labeled as an
  approximate public API value or explicitly unavailable.
- **CONDITIONAL GO:** the primary path passes, but force-quit, reboot, or
  SideStore has a documented limitation that can be handled by honest copy and a
  manual fallback.
- **NO-GO:** the intents are unavailable, locked automatic start/stop fails, the
  activity cannot render, or neither agreed installation path preserves the
  widget extension.

### Current recommendation

**Phase 0/1 is complete with a CONDITIONAL GO.** Planning for the next phase may
begin if the product accepts these constraints:

- after a reboot, the user must unlock once and may need to launch ChargeGlow
  before relying on the charger automations;
- the public battery percentage is approximate and can become stale while iOS
  suspends execution;
- free signing and iLoader are test-only installation mechanisms;
- SideStore remains an optional compatibility path and was not required for the
  primary USB decision.

The remaining unrun authorization, rapid-reconnect, Low Power Mode, and 100%
rows are follow-up hardening tests. They do not reverse the demonstrated
feasibility of the primary flow, but should be completed before calling a later
MVP production-ready.
