#!/usr/bin/env python3
import argparse
from datetime import date
from html import escape
from pathlib import Path
import xml.etree.ElementTree as ET

APP_ID = "com.ayugram.desktop"


def pages_url(repository: str) -> str:
    owner, name = repository.split("/", 1)
    if name.lower() == f"{owner.lower()}.github.io":
        return f"https://{owner.lower()}.github.io"
    return f"https://{owner.lower()}.github.io/{name}"


def update_metainfo(path: Path, version: str, release_date: str, release_url: str) -> None:
    tree = ET.parse(path)
    root = tree.getroot()
    releases = root.find("releases")
    if releases is None:
        releases = ET.SubElement(root, "releases")
    for current in list(releases):
        releases.remove(current)
    release = ET.SubElement(
        releases,
        "release",
        {"version": version, "date": release_date, "type": "stable"},
    )
    release.set("url", release_url)
    ET.indent(tree, space="  ")
    tree.write(path, encoding="utf-8", xml_declaration=True)


def write_site(site_dir: Path, repository: str, version: str) -> None:
    base_url = pages_url(repository)
    flatpakref_url = f"{base_url}/{APP_ID}.flatpakref"
    site_dir.mkdir(parents=True, exist_ok=True)
    (site_dir / ".nojekyll").write_text("", encoding="utf-8")
    (site_dir / "version").write_text(f"{version}\n", encoding="utf-8")
    (site_dir / f"{APP_ID}.flatpakref").write_text(
        "[Flatpak Ref]\n"
        f"Name={APP_ID}\n"
        "Branch=master\n"
        "Title=AyuGram Desktop\n"
        f"Url={base_url}/repo\n"
        "IsRuntime=false\n"
        "RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo\n",
        encoding="utf-8",
    )
    install_command = f"flatpak install --user --from {flatpakref_url}"
    update_command = "flatpak update"
    (site_dir / "index.html").write_text(
        "<!doctype html>\n"
        '<html lang="en"><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        "<title>AyuGram Desktop Flatpak</title>"
        "<body><main><h1>AyuGram Desktop Flatpak</h1>"
        f"<p>Version {escape(version)}</p>"
        "<p>Install:</p>"
        f"<pre><code>{escape(install_command)}</code></pre>"
        "<p>Update:</p>"
        f"<pre><code>{escape(update_command)}</code></pre>"
        "<p>Updates are delivered through Flatpak's native repository support.</p>"
        f'<p><a href="{escape(flatpakref_url)}">Flatpak repository file</a></p>'
        "</main></body></html>\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--date", default=date.today().isoformat())
    parser.add_argument("--release-url", required=True)
    parser.add_argument("--site-dir", type=Path, default=Path("_site"))
    args = parser.parse_args()

    update_metainfo(
        Path("share/metainfo/com.ayugram.desktop.metainfo.xml"),
        args.version,
        args.date,
        args.release_url,
    )
    write_site(args.site_dir, args.repository, args.version)


if __name__ == "__main__":
    main()
