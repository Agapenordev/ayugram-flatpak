#!/usr/bin/env bash
set -euo pipefail

app_id=com.ayugram.desktop
flatpakref_url="${AYUGRAM_FLATPAKREF_URL:-https://agapenordev.github.io/ayugram-flatpak/com.ayugram.desktop.flatpakref}"

if [[ $(id -u) -eq 0 ]]; then
    echo "Run this installer as your regular user, without sudo." >&2
    exit 1
fi
if ! command -v flatpak >/dev/null 2>&1; then
    echo "Flatpak is required. Install it first: https://flatpak.org/setup/" >&2
    exit 1
fi

if flatpak info --user "$app_id" >/dev/null 2>&1; then
    flatpak update --user --assumeyes --noninteractive "$app_id"
else
    flatpak install --user --assumeyes --noninteractive --from "$flatpakref_url"
fi

if [[ ${AYUGRAM_AUTO_UPDATE:-1} == 1 ]] && command -v systemctl >/dev/null 2>&1; then
    unit_dir="$HOME/.config/systemd/user"
    flatpak_path=$(command -v flatpak)
    mkdir -p "$unit_dir"
    cat > "$unit_dir/ayugram-flatpak-update.service" <<EOF
[Unit]
Description=Update AyuGram Desktop Flatpak

[Service]
Type=oneshot
ExecStart=$flatpak_path update --user --assumeyes --noninteractive $app_id
EOF
    cat > "$unit_dir/ayugram-flatpak-update.timer" <<'EOF'
[Unit]
Description=Check for AyuGram Desktop updates daily

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF
    if systemctl --user daemon-reload && \
        systemctl --user enable --now ayugram-flatpak-update.timer; then
        echo "Automatic daily updates are enabled."
    else
        echo "Could not enable the update timer; your software center can still apply updates." >&2
    fi
fi

echo "AyuGram Desktop is ready. Launch it with: flatpak run $app_id"
