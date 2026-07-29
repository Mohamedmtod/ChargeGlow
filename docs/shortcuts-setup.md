# Shortcuts Charger Automation Setup

These instructions describe user-created personal automations. ChargeGlow
cannot create, inspect, or confirm them through a public API.

## Before setup

1. Install and trust ChargeGlow.
2. Launch it once.
3. Confirm Live Activities show as enabled in the app.
4. Open Shortcuts and search ChargeGlow actions.

If the actions do not appear, restart Shortcuts, reopen ChargeGlow, and capture
diagnostics before reinstalling.

## Connected automation

1. Open **Shortcuts > Automation**.
2. Create a new personal automation.
3. Choose **Charger**.
4. Select **Is Connected**.
5. Add the ChargeGlow action **Start Charging Theme**.
6. Configure it to run automatically without asking where the installed iOS
   version permits.
7. Save and capture a screenshot of the final configuration.

## Disconnected automation

1. Create another **Charger** personal automation.
2. Select **Is Disconnected**.
3. Add **Stop Charging Theme**.
4. Configure automatic execution where permitted.
5. Save and capture a screenshot.

## Test

1. Use the app's Stop button to establish a stopped state.
2. Lock the iPhone.
3. Connect the charger and observe the Lock Screen.
4. Confirm exactly one ChargeGlow Live Activity appears.
5. Disconnect the charger and confirm it disappears.
6. Export app, Codemagic, and iLoader logs if either step fails.
