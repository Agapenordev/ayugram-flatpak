#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <upstream-tag>" >&2
    exit 64
fi

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root_dir"

for tool in docker flatpak flatpak-builder git poetry python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing required tool: $tool" >&2
        exit 1
    fi
done

upstream_tag=$1
work_dir="$root_dir/.build"
source_dir="$work_dir/source"
package_dir="$work_dir/package"
repo_dir="$root_dir/_site/repo"

rm -rf "$source_dir" "$package_dir" "$work_dir/build-dir"
mkdir -p "$work_dir" "$repo_dir"

git clone --depth 1 --branch "$upstream_tag" \
    https://github.com/AyuGram/AyuGramDesktop.git "$source_dir"
git -C "$source_dir" config \
    url.https://github.com/repomansez/cppgir.git.insteadOf \
    https://gitlab.com/mnauw/cppgir.git

for attempt in 1 2 3; do
    if git -C "$source_dir" -c submodule.fetchJobs=2 \
        submodule update --init --recursive --depth 1; then
        break
    fi
    if [[ $attempt -eq 3 ]]; then
        exit 1
    fi
    sleep $((attempt * 10))
done

(
    cd "$source_dir"
    ./Telegram/build/prepare/linux.sh
)

docker run --rm \
    -u root \
    -e TDESKTOP_API_ID="${TDESKTOP_API_ID:-2040}" \
    -e TDESKTOP_API_HASH="${TDESKTOP_API_HASH:-b18441a1ff607e10a989891a5462e627}" \
    -v "$source_dir:/usr/src/tdesktop" \
    tdesktop:centos_env \
    /usr/src/tdesktop/Telegram/build/docker/centos_env/build.sh \
    -D TDESKTOP_API_ID="${TDESKTOP_API_ID:-2040}" \
    -D TDESKTOP_API_HASH="${TDESKTOP_API_HASH:-b18441a1ff607e10a989891a5462e627}"

test -x "$source_dir/out/Release/AyuGram"
mkdir -p "$package_dir"
cp "$source_dir/out/Release/AyuGram" "$package_dir/AyuGram"
cp "$root_dir/com.ayugram.desktop.yml" "$package_dir/"
cp -a "$root_dir/share" "$package_dir/"

flatpak remote-add --user --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --assumeyes --noninteractive flathub org.gnome.Sdk//50
flatpak-builder --force-clean --disable-rofiles-fuse \
    --repo="$repo_dir" "$work_dir/build-dir" "$package_dir/com.ayugram.desktop.yml"

echo "Flatpak repository built in $repo_dir"
