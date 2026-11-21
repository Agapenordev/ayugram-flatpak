#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote


def get_release(repository: str, tag: str | None) -> dict:
    if tag:
        endpoint = f"releases/tags/{quote(tag, safe='')}"
    else:
        endpoint = "releases/latest"
    request = Request(
        f"https://api.github.com/repos/{repository}/{endpoint}",
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "ayugram-flatpak-release-checker",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", default="AyuGram/AyuGramDesktop")
    parser.add_argument("--tag")
    parser.add_argument("--github-output")
    args = parser.parse_args()

    release = get_release(args.repository, args.tag)
    if release.get("draft") or release.get("prerelease"):
        raise SystemExit("Only stable, published AyuGram releases can be packaged")

    tag = release["tag_name"]
    version = tag.removeprefix("v")
    outputs = {
        "upstream_tag": tag,
        "app_version": version,
        "release_date": release["published_at"][:10],
        "upstream_release_url": release["html_url"],
    }
    for key, value in outputs.items():
        print(f"{key}={value}")
    if args.github_output:
        with Path(args.github_output).open("a", encoding="utf-8") as output:
            for key, value in outputs.items():
                output.write(f"{key}={value}\n")


if __name__ == "__main__":
    main()
