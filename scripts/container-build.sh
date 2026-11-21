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

rust_toolchain=$(sed -n 's/^RUST_TOOLCHAIN=//p' "$dockerfile" | head -n 1)
patches_commit=$(awk '/^FROM builder AS patches/{found=1} found && /git fetch --depth=1 origin/ {print $NF; exit}' "$dockerfile")
tlottie_commit=$(awk '/^FROM patches AS tlottie/{found=1} found && /git fetch --depth=1 origin/ {print $NF; exit}' "$dockerfile")
if [[ -z $rust_toolchain || -z $patches_commit || -z $tlottie_commit ]]; then
    echo "Could not determine the tlottie build inputs from $dockerfile" >&2
    exit 1
fi

git init /tmp/patches
git -C /tmp/patches remote add origin https://github.com/desktop-app/patches.git
git -C /tmp/patches fetch --depth=1 origin "$patches_commit"
git -C /tmp/patches reset --hard FETCH_HEAD

git init /tmp/tlottie
git -C /tmp/tlottie remote add origin https://github.com/dkaraush/tlottie.git
git -C /tmp/tlottie fetch --depth=1 origin "$tlottie_commit"
git -C /tmp/tlottie reset --hard FETCH_HEAD
git -C /tmp/tlottie apply /tmp/patches/tlottie.patch

export RUSTUP_HOME=/tmp/rustup
export CARGO_HOME=/tmp/cargo
export RUSTUP_TOOLCHAIN=$rust_toolchain
export PATH=$CARGO_HOME/bin:$PATH
wget -O /tmp/rustup-init.sh https://sh.rustup.rs
sh /tmp/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain "$rust_toolchain"
(
    cd /tmp/tlottie
    cargo rustc --lib --release --locked \
        --features c-api --crate-type staticlib \
        --target x86_64-unknown-linux-gnu \
        -- --print native-static-libs
    objcopy --strip-debug target/x86_64-unknown-linux-gnu/release/libtlottie.a
    install -Dm644 target/x86_64-unknown-linux-gnu/release/libtlottie.a /usr/local/lib/libtlottie.a
    install -Dm644 include/tlottie.h /usr/local/include/tlottie/tlottie.h
)
rm -rf /tmp/patches /tmp/tlottie /tmp/rustup /tmp/cargo /tmp/rustup-init.sh

exec /usr/src/tdesktop/Telegram/build/docker/centos_env/build.sh \
    -D TDESKTOP_API_ID="${TDESKTOP_API_ID:?}" \
    -D TDESKTOP_API_HASH="${TDESKTOP_API_HASH:?}"
