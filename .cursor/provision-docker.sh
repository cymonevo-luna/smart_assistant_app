#!/usr/bin/env bash
# Docker + compose for smart_assistant_api local stack (postgres, redis, api).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

install -m 0755 -d /etc/apt/keyrings
curl --retry 3 --retry-delay 5 -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  fuse-overlayfs \
  iptables
rm -rf /var/lib/apt/lists/*

mkdir -p /etc/docker
printf '%s\n' '{' '  "storage-driver": "fuse-overlayfs"' '}' >/etc/docker/daemon.json
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

groupadd -f docker
if id ubuntu >/dev/null 2>&1; then
  usermod -aG docker ubuntu || true
fi
