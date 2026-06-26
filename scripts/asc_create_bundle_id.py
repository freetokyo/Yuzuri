#!/usr/bin/env python3
"""Create the Yuzuri Bundle ID via App Store Connect API.

Credentials come from ENV ONLY (never hardcoded here):
  ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH
Bundle id comes from scripts/yuzuri_metadata.json.

Note (known limitation): the App *entity* itself cannot be created via API
(403). Create the Bundle ID here, then create the App in the ASC Web UI and
record its adam id in PROJECT_CONTEXT.md.

Usage: python3 scripts/asc_create_bundle_id.py
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

ISSUER_ID = os.environ.get("ASC_ISSUER_ID")
KEY_ID = os.environ.get("ASC_KEY_ID")
KEY_PATH = os.environ.get("ASC_PRIVATE_KEY_PATH")

META = Path(__file__).parent / "yuzuri_metadata.json"
BASE = "https://api.appstoreconnect.apple.com/v1"


def require_creds() -> None:
    missing = [n for n, v in
               (("ASC_ISSUER_ID", ISSUER_ID), ("ASC_KEY_ID", KEY_ID), ("ASC_PRIVATE_KEY_PATH", KEY_PATH))
               if not v]
    if missing:
        print(f"!! set env: {', '.join(missing)}", file=sys.stderr)
        sys.exit(2)


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        Path(KEY_PATH).read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def main() -> int:
    require_creds()
    meta = json.loads(META.read_text())
    bundle_id = meta["app"]["bundle_id"]
    name = "Yuzuri"

    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    r = requests.get(f"{BASE}/bundleIds", headers=headers,
                     params={"filter[identifier]": bundle_id, "limit": 200}, timeout=30)
    r.raise_for_status()
    for b in r.json().get("data", []):
        if b["attributes"]["identifier"] == bundle_id:
            print(f"[exists] {bundle_id} (id={b['id']})")
            return 0

    payload = {"data": {"type": "bundleIds", "attributes":
               {"identifier": bundle_id, "name": name, "platform": "IOS"}}}
    r = requests.post(f"{BASE}/bundleIds", headers=headers, json=payload, timeout=30)
    if r.status_code >= 300:
        print(f"[error] {r.status_code}: {r.text}", file=sys.stderr)
        return 1
    print(f"[created] {bundle_id} (id={r.json()['data']['id']})")
    print("次: ASC Web UI で App 本体を作成し adam id を PROJECT_CONTEXT.md へ。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
