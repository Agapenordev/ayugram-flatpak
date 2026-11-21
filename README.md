# AyuGram Desktop Flatpak

Unofficial Flatpak packaging for [AyuGram Desktop](https://github.com/AyuGram/AyuGramDesktop), built from the upstream stable source tags. GitHub Actions publishes a Flatpak repository to GitHub Pages, so installations receive updates through Flatpak.

## Install

```bash
flatpak install --user --from https://agapenordev.github.io/ayugram-flatpak/com.ayugram.desktop.flatpakref
```

## Update

```bash
flatpak update
```

Once installed from the repository, AyuGram updates through Flatpak alongside your other Flatpak apps. No custom installer, updater, or systemd timer is used. Desktop software centers can also apply these updates automatically.

Every upstream release creates a versioned [GitHub Release](https://github.com/Agapenordev/ayugram-flatpak/releases) with a standalone `.flatpak` bundle. Use the repository installation above if you want updates through `flatpak update`.

Launch AyuGram with:

```bash
flatpak run com.ayugram.desktop
```

## Publishing setup

1. Push this repository to GitHub as `Agapenordev/ayugram-flatpak` with `main` as the default branch.
2. In **Settings → Pages**, select **GitHub Actions** as the deployment source.
3. Open **Actions → Build and publish AyuGram Flatpak → Run workflow** for the first build. Subsequent checks run every six hours.
4. Ensure Actions has permission to deploy Pages if your organization restricts the default token.

The build uses AyuGram's documented Telegram API credentials by default. Repository secrets `TDESKTOP_API_ID` and `TDESKTOP_API_HASH` can override them. Builds run on `ubuntu-latest`; set the `BUILD_RUNNER` repository variable to a self-hosted runner label if more disk space or build time is needed.

If you use a different repository name or owner, change the Pages URL in this README. CI derives the published repository URL from `GITHUB_REPOSITORY` automatically.

## Build locally

A source build needs Docker, Git, Python, Poetry, Flatpak, and `flatpak-builder`. It requires substantial disk space and can take several hours.

```bash
python3 scripts/upstream_release.py --tag v7.2.9
python3 scripts/prepare_release.py \
  --repository Agapenordev/ayugram-flatpak \
  --version 7.2.9 \
  --date 2026-10-05 \
  --release-url https://github.com/AyuGram/AyuGramDesktop/releases/tag/v7.2.9
./scripts/build.sh v7.2.9
```

The resulting OSTree repository is in `_site/repo`, and the standalone bundle is in `.build`. The workflow only replaces the published site after a successful build.

## Packaging notes

- Application ID: `com.ayugram.desktop`
- Runtime: `org.gnome.Platform//50`
- Only stable, non-draft upstream releases are selected automatically.
- The repository is served over HTTPS; standard Flatpak updates use the published OSTree refs.
- Packaging resources are based on the [community AyuGram Flatpak packaging](https://github.com/0FL01/AyuGramDesktop-flatpak).
