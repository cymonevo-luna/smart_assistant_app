FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_ROOT=/opt/flutter
ENV ANDROID_HOME=/home/ubuntu/Android/Sdk
ENV ANDROID_SDK_ROOT=/home/ubuntu/Android/Sdk
ENV PATH=/opt/flutter/bin:/home/ubuntu/Android/Sdk/cmdline-tools/latest/bin:/home/ubuntu/Android/Sdk/platform-tools:/home/ubuntu/Android/Sdk/emulator:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/ubuntu

COPY provision-android.sh provision-docker.sh /tmp/luna-provision/
RUN chmod +x /tmp/luna-provision/*.sh \
  && /tmp/luna-provision/provision-android.sh \
  && /tmp/luna-provision/provision-docker.sh \
  && rm -rf /tmp/luna-provision

USER ubuntu
WORKDIR /home/ubuntu
