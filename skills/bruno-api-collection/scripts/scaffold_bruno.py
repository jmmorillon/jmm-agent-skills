#!/usr/bin/env python3
"""
Scaffold the deterministic skeleton of a /bruno collection at a project root.

This creates ONLY the boilerplate that is identical for every collection —
bruno.json, collection.bru, the exposed/ and upstream/ folders with their
folder.bru, the environment files, .env / .env.example, and the .gitignore
entry. It deliberately does NOT invent request files: those must be derived
from the project's actual code (see SKILL.md, "Discover the API surface").

It is idempotent — existing files are never overwritten, and the .gitignore
entry is only appended when missing — so it is safe to run on a collection
that already exists (e.g. to add a new environment).

Usage:
  python3 scaffold_bruno.py --root . --name my-api
  python3 scaffold_bruno.py --root . --name whatsapp-app \
      --envs local,staging,production \
      --secrets WA_ACCESS_TOKEN,WA_VERIFY_TOKEN \
      --base-urls local=http://localhost:8080,staging=https://preprod.example.com

Notes:
  --secrets are wired into every environment as `name: {{process.env.NAME}}`
    using a lowerCamelCase variable name, and listed (empty) in .env.example.
  --base-urls sets each env's baseUrl; any env without one gets a TODO placeholder.
"""
import argparse
import json
import os
import re
import sys


def camel(env_name: str) -> str:
    """SNAKE_CASE / kebab -> lowerCamelCase for a Bruno variable name."""
    parts = re.split(r"[^A-Za-z0-9]+", env_name.lower())
    parts = [p for p in parts if p]
    if not parts:
        return env_name
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def write_if_absent(path: str, content: str, created: list, skipped: list):
    if os.path.exists(path):
        skipped.append(path)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(content)
    created.append(path)


def ensure_gitignore(root: str, entry: str, changed: list):
    gi = os.path.join(root, ".gitignore")
    lines = []
    if os.path.exists(gi):
        with open(gi, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    if any(l.strip() == entry for l in lines):
        return
    with open(gi, "a", encoding="utf-8") as fh:
        if lines and lines[-1].strip() != "":
            fh.write("\n")
        fh.write(f"# Bruno secrets (never commit real tokens)\n{entry}\n")
    changed.append(gi)


def main():
    ap = argparse.ArgumentParser(description="Scaffold a /bruno collection skeleton.")
    ap.add_argument("--root", default=".", help="Project root where /bruno is created")
    ap.add_argument("--name", required=True, help="Collection name (shown in Bruno)")
    ap.add_argument("--envs", default="local,staging,production",
                    help="Comma-separated environment names")
    ap.add_argument("--secrets", default="",
                    help="Comma-separated secret env-var names for .env / .env.example")
    ap.add_argument("--base-urls", default="",
                    help="Comma-separated env=url pairs, e.g. local=http://localhost:8080")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    bruno = os.path.join(root, "bruno")
    envs = [e.strip() for e in args.envs.split(",") if e.strip()]
    secrets = [s.strip() for s in args.secrets.split(",") if s.strip()]
    base_urls = {}
    for pair in args.base_urls.split(","):
        if "=" in pair:
            k, v = pair.split("=", 1)
            base_urls[k.strip()] = v.strip()

    created, skipped, changed = [], [], []

    # bruno.json
    write_if_absent(
        os.path.join(bruno, "bruno.json"),
        json.dumps({
            "version": "1",
            "name": args.name,
            "type": "collection",
            "ignore": ["node_modules", ".git", ".env"],
        }, indent=2) + "\n",
        created, skipped,
    )

    # collection.bru — shared defaults
    write_if_absent(
        os.path.join(bruno, "collection.bru"),
        "headers {\n  Content-Type: application/json\n}\n\n"
        "docs {\n  API collection for " + args.name + ".\n"
        "  `exposed/` = endpoints this project publishes. "
        "`upstream/` = third-party APIs it consumes.\n}\n",
        created, skipped,
    )

    # exposed/ and upstream/ folder markers
    write_if_absent(os.path.join(bruno, "exposed", "folder.bru"),
                    "meta {\n  name: Exposed API\n  seq: 1\n}\n", created, skipped)
    write_if_absent(os.path.join(bruno, "upstream", "folder.bru"),
                    "meta {\n  name: Upstream API\n  seq: 2\n}\n", created, skipped)

    # environments
    secret_lines = "".join(
        f"  {camel(s)}: {{{{process.env.{s}}}}}\n" for s in secrets
    )
    for env in envs:
        url = base_urls.get(env, f"https://TODO.set.{env}.url")
        write_if_absent(
            os.path.join(bruno, "environments", f"{env}.bru"),
            "vars {\n"
            f"  baseUrl: {url}\n"
            f"{secret_lines}"
            "}\n",
            created, skipped,
        )

    # .env.example (committed) and .env (gitignored)
    example = "".join(f"{s}=\n" for s in secrets) or "# Add secret keys here, e.g. API_TOKEN=\n"
    write_if_absent(os.path.join(bruno, ".env.example"), example, created, skipped)
    write_if_absent(os.path.join(bruno, ".env"), example, created, skipped)

    # .gitignore
    ensure_gitignore(root, "bruno/.env", changed)

    def rel(p):
        return os.path.relpath(p, root)

    print("Scaffold complete under", rel(bruno) + "/")
    if created:
        print("\nCreated:")
        for p in sorted(created):
            print("  +", rel(p))
    if skipped:
        print("\nAlready existed (left untouched):")
        for p in sorted(skipped):
            print("  =", rel(p))
    if changed:
        print("\nUpdated:")
        for p in sorted(changed):
            print("  ~", rel(p))
    print(
        "\nNext: add one .bru request per endpoint under exposed/ (and upstream/ "
        "for outbound calls), derived from the project's code. See references/bru-syntax.md."
    )


if __name__ == "__main__":
    sys.exit(main())
