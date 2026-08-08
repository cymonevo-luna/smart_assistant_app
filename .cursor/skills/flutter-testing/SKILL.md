---
name: flutter-testing
description: >-
  Run Flutter tests using the host's shared Flutter SDK and optional shared
  Android emulator. Use when testing Flutter apps, integration tests, device
  tests, emulator setup, or when an agent needs flutter test commands. Prevents
  reinstalling Flutter/SDK and booting duplicate emulators.
---

# Flutter testing (Luna)

Use the **host-installed** Flutter SDK and Android SDK. Never bootstrap tooling
inside an agent run.

## Before any Flutter test command

From the app repo root (e.g. `luna_pos_app/`):

```bash
scripts/ensure-flutter-test-env.sh
eval "$(scripts/ensure-flutter-test-env.sh --export)"
```

If the script reports missing Flutter or Android SDK, **stop** and tell the user.
Do **not** run `sdkmanager`, `avdmanager`, `flutter upgrade`, or download system
images.

### Host paths (this machine)

| Tool | Location |
| --- | --- |
| Flutter | `/snap/bin/flutter` (or `flutter` on PATH) |
| Android SDK | `$HOME/Android/Sdk` |
| Shared AVD | **`Luna_Test_Lite`** only (Nexus 5X, x86_64 API 34, 1536 MB, 1 vCPU) |

Export (also printed by the ensure script):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
export SHARED_AVD=Luna_Test_Lite
```

**Agents must not use any other AVD** (including legacy `Pixel_9_Pro`). Tier 2
tests go through `scripts/start-shared-emulator.sh`, which enforces
`Luna_Test_Lite`.

## Test tiers (strict order)

### Tier 1 — default for every agent task

Run on the VM; **no device or emulator**:

```bash
flutter test                    # unit + widget
flutter test test/integration/  # mocked integration checklist
```

Use mocks (`MockBluetoothPrinterService`, `integration_test/helpers/harness.dart`
stubs) for platform APIs unless the task explicitly requires real OS dialogs.

### Tier 2 — device/integration_test (only when necessary)

Run **only** when the change needs real platform behavior (permission dialogs,
Bluetooth stack, camera, etc.) and Tier 1 cannot cover it.

1. Reuse a running emulator — **never start a second one**:

```bash
scripts/start-shared-emulator.sh   # prints emulator-5554 or reuses existing
DEVICE="$(scripts/start-shared-emulator.sh | tail -n1)"
flutter test integration_test/ -d "$DEVICE"
```

2. If no emulator is available and Tier 2 is not strictly required, **skip**
   device tests, say so explicitly, and rely on Tier 1.

### Forbidden during agent runs

- Installing Flutter or the Android SDK
- Creating new AVDs or downloading emulator system images
- Starting another emulator when one is already running
- Using any AVD other than **`Luna_Test_Lite`**
- Invoking `adb` from inside the app under test (use host-side scripts instead)
- Spending a session on emulator setup when Tier 1 tests suffice

## Shared emulator (host)

Start once and keep warm between sessions:

```bash
scripts/start-shared-emulator.sh
```

Stop:

```bash
scripts/stop-shared-emulator.sh
```

Optional user systemd service (install once on the host):

```bash
mkdir -p ~/.config/systemd/user
cp scripts/systemd/luna-shared-emulator.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now luna-shared-emulator.service
```

Check status: `systemctl --user status luna-shared-emulator.service`

## KVM (slow emulator fix)

If `ensure-flutter-test-env.sh` warns that KVM is unavailable, emulators run in
software mode and may ANR. Fix on the host once:

```bash
sudo usermod -aG kvm "$USER"
# log out and back in, then verify:
test -w /dev/kvm && echo "KVM ready"
```

`start-shared-emulator.sh` uses `sg kvm` when group membership is set but the
current shell has not refreshed groups yet.

Do not work around slow emulators by downloading ARM images or alternate AVDs.

## luna_pos_app auth rules

When testing `luna_pos_app`, also follow `.cursor/rules/tester-agent-auth.mdc`:
use seeded test accounts only; never register users in automation.

## Completion checklist

Before marking Flutter work done:

- [ ] Tier 1 tests pass (`flutter test` + `test/integration/` when applicable)
- [ ] Tier 2 run only if required; shared `Luna_Test_Lite` emulator reused, not recreated
- [ ] Missing tooling reported explicitly — not silently skipped
