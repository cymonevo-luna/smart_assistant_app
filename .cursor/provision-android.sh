#!/usr/bin/env bash
# Provision Flutter SDK, Android SDK, and Luna_Test_Lite AVD for Cloud Agent builds.
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-/home/ubuntu/Android/Sdk}"
FLUTTER_ROOT="${FLUTTER_ROOT:-/opt/flutter}"
SHARED_AVD="Luna_Test_Lite"
CMDLINE_TOOLS_ZIP="commandlinetools-linux-11076708_latest.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  openjdk-17-jdk-headless \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  libpulse0 \
  libx11-6 \
  libxcb1 \
  libxcomposite1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxtst6 \
  libx11-xcb1 \
  libxkbcommon0 \
  qemu-kvm

rm -rf /var/lib/apt/lists/*

if [ ! -d "$FLUTTER_ROOT/.git" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

mkdir -p "$ANDROID_HOME/cmdline-tools"
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  curl -fsSL "$CMDLINE_TOOLS_URL" -o "/tmp/${CMDLINE_TOOLS_ZIP}"
  unzip -q "/tmp/${CMDLINE_TOOLS_ZIP}" -d /tmp/android-cmdline-tools
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv /tmp/android-cmdline-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf /tmp/android-cmdline-tools "/tmp/${CMDLINE_TOOLS_ZIP}"
fi

export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

if id ubuntu >/dev/null 2>&1; then
  chown -R ubuntu:ubuntu "$ANDROID_HOME" "$FLUTTER_ROOT" 2>/dev/null || true
fi

yes | sdkmanager --licenses >/dev/null
sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-34" \
  "system-images;android-34;google_apis;x86_64"

if ! "$ANDROID_HOME/emulator/emulator" -list-avds | grep -Fxq "$SHARED_AVD"; then
  echo no | avdmanager create avd \
    -n "$SHARED_AVD" \
    -k "system-images;android-34;google_apis;x86_64" \
    -d "Nexus 5X"
fi

AVD_CONFIG="$HOME/.android/avd/${SHARED_AVD}.avd/config.ini"
if [ -f "$AVD_CONFIG" ]; then
  sed -i '/^hw\.ramSize=/d;/^hw\.cpu\.ncore=/d' "$AVD_CONFIG"
  printf '%s\n' 'hw.ramSize=1536' 'hw.cpu.ncore=1' >>"$AVD_CONFIG"
fi

flutter config --no-analytics
flutter precache --android
flutter doctor -v

cat >/etc/profile.d/luna-flutter-android.sh <<EOF
export FLUTTER_ROOT="$FLUTTER_ROOT"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="\$FLUTTER_ROOT/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$PATH"
export SHARED_AVD="$SHARED_AVD"
EOF

getent group kvm >/dev/null || groupadd -r kvm
if id ubuntu >/dev/null 2>&1; then
  usermod -aG kvm ubuntu || true
  if getent group rdma >/dev/null; then
    usermod -aG rdma ubuntu || true
  fi
fi
