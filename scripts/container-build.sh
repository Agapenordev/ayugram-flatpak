#!/usr/bin/env bash
set -euo pipefail

dockerfile=/usr/src/tdesktop/Telegram/build/docker/centos_env/Dockerfile
ada_version=$(sed -nE 's|.*git clone -b (v[^ ]+).*https://github.com/ada-url/ada.git.*|\1|p' "$dockerfile")
if [[ -z $ada_version ]]; then
    echo "Could not determine the ada version from $dockerfile" >&2
    exit 1
fi

rm -rf /tmp/ada
git clone -b "$ada_version" --depth 1 https://github.com/ada-url/ada.git /tmp/ada
cmake -S /tmp/ada -B /tmp/ada/build \
    -DADA_TESTING=OFF \
    -DADA_TOOLS=OFF \
    -DADA_INCLUDE_URL_PATTERN=OFF
cmake --build /tmp/ada/build
cmake --install /tmp/ada/build
rm -rf /tmp/ada

exec /usr/src/tdesktop/Telegram/build/docker/centos_env/build.sh \
    -D TDESKTOP_API_ID="${TDESKTOP_API_ID:?}" \
    -D TDESKTOP_API_HASH="${TDESKTOP_API_HASH:?}"
