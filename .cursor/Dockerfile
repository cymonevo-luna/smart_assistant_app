FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.44.9
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_HOME=/home/ubuntu/Android/Sdk

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ANDROID_HOME=${ANDROID_HOME} \
    ANDROID_SDK_ROOT=${ANDROID_HOME} \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PATH=/opt/flutter/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}

# Docker's default RUN shell is /bin/sh (dash on Ubuntu), which does not
# support "set -o pipefail" used below to make the `yes | sdkmanager
# --licenses` step fail loudly on real errors while ignoring the SIGPIPE
# `yes` gets once sdkmanager stops reading. Switch to bash for all RUN
# instructions.
SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        cmake \
        curl \
        git \
        libgtk-3-dev \
        libnss3 \
        libpulse0 \
        ninja-build \
        openjdk-17-jdk \
        pkg-config \
        qemu-kvm \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter --version \
    && flutter config --no-analytics \
    && flutter precache --android

RUN groupadd -g 1000 ubuntu || true \
    && useradd -m -u 1000 -g 1000 -s /bin/bash ubuntu || true \
    && groupadd -r kvm 2>/dev/null || true \
    && usermod -aG kvm ubuntu \
    && mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
        -o /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip \
    && set +o pipefail \
    && yes | sdkmanager --licenses >/dev/null \
    && set -o pipefail \
    && sdkmanager --install \
        "platform-tools" \
        "emulator" \
        "build-tools;34.0.0" \
        "platforms;android-34" \
        "platforms;android-36" \
        "system-images;android-34;google_apis;x86_64" \
    && test -x "${ANDROID_HOME}/platform-tools/adb" \
    && test -x "${ANDROID_HOME}/emulator/emulator" \
    && test -d "${ANDROID_HOME}/system-images/android-34/google_apis/x86_64" \
    && chown -R ubuntu:ubuntu /opt/flutter "${ANDROID_HOME}"

RUN cat > /etc/profile.d/luna-flutter-android.sh <<'EOF'
export ANDROID_HOME="/home/ubuntu/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="/opt/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
EOF

RUN chmod 644 /etc/profile.d/luna-flutter-android.sh \
    && ln -sf /opt/flutter/bin/flutter /usr/local/bin/flutter \
    && ln -sf /opt/flutter/bin/dart /usr/local/bin/dart

USER ubuntu
WORKDIR /home/ubuntu

# Luna agent device tests require this exact AVD (Nexus 5X, API 34). RAM/cores are
# enforced at runtime by scripts/start-shared-emulator.sh (-memory 1536 -cores 1).
RUN echo no | avdmanager create avd \
        -n Luna_Test_Lite \
        -k "system-images;android-34;google_apis;x86_64" \
        -d "Nexus 5X" \
    && test -d "$HOME/.android/avd/Luna_Test_Lite.avd" \
    && "$ANDROID_HOME/emulator/emulator" -list-avds | grep -Fxq Luna_Test_Lite

RUN flutter doctor -v
