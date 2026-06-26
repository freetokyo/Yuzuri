#!/usr/bin/env python3
"""Sync Yuzuri App Store metadata to ASC (dry-run by default).

Credentials from ENV ONLY: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH.
Content from scripts/yuzuri_metadata.json.

ASC field length limits (validated before sync):
  name<=30  subtitle<=30  keywords<=100  promotionalText<=170  description<=4000

Usage:
  python3 scripts/asc_sync_metadata.py            # dry-run: validate + print
  python3 scripts/asc_sync_metadata.py --apply    # actually PATCH ASC
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

META = Path(__file__).parent / "yuzuri_metadata.json"
LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170, "description": 4000}
BASE = "https://api.appstoreconnect.apple.com/v1"
# PATCH 可能な appStoreVersion の状態。
EDITABLE_STATES = {
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW",
}
APP_INFO_FIELDS = ("name", "subtitle", "privacyPolicyUrl")
VERSION_FIELDS = ("description", "keywords", "promotionalText", "marketingUrl", "supportUrl")


def token() -> str:
    import jwt
    iss, kid, p8 = (os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_ID"],
                    os.environ["ASC_PRIVATE_KEY_PATH"])
    now = int(time.time())
    return jwt.encode({"iss": iss, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      Path(p8).read_text(), algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def sync_localization(loc: dict, app_id: str, headers: dict) -> None:
    import requests
    locale = loc.get("locale")
    info = loc.get("app_info", {})
    version = loc.get("version", {})

    # --- 1) appInfoLocalizations（name / subtitle / privacyPolicyUrl）---
    app_infos = requests.get(f"{BASE}/apps/{app_id}/appInfos", headers=headers).json().get("data", [])
    patched_info = False
    for ai in app_infos:
        locs = requests.get(f"{BASE}/appInfos/{ai['id']}/appInfoLocalizations",
                            headers=headers).json().get("data", [])
        target = next((l for l in locs if l["attributes"].get("locale") == locale), None)
        if not target:
            continue
        attrs = {k: info[k] for k in APP_INFO_FIELDS if k in info}
        if attrs:
            body = {"data": {"type": "appInfoLocalizations", "id": target["id"], "attributes": attrs}}
            r = requests.patch(f"{BASE}/appInfoLocalizations/{target['id']}", headers=headers, json=body)
            if r.status_code in (200, 201):
                print(f"  [{locale}] appInfo PATCH OK: {', '.join(attrs)}")
                patched_info = True
            else:
                print(f"  !! [{locale}] appInfo PATCH {r.status_code}: {r.text[:200]}", file=sys.stderr)
        break
    if not patched_info:
        print(f"  !! [{locale}] appInfoLocalization が見つからず未更新", file=sys.stderr)

    # --- 2) appStoreVersionLocalizations（description / keywords / promo / urls）---
    versions = requests.get(f"{BASE}/apps/{app_id}/appStoreVersions", headers=headers).json().get("data", [])
    editable = next((v for v in versions
                     if v["attributes"].get("appStoreState") in EDITABLE_STATES), None)
    if not editable:
        print(f"  !! 編集可能な appStoreVersion が無い（1.0 を ASC で用意してください）", file=sys.stderr)
        return
    vstr = editable["attributes"].get("versionString")
    vlocs = requests.get(f"{BASE}/appStoreVersions/{editable['id']}/appStoreVersionLocalizations",
                         headers=headers).json().get("data", [])
    target = next((l for l in vlocs if l["attributes"].get("locale") == locale), None)
    if not target:
        print(f"  !! [{locale}] appStoreVersionLocalization が無い", file=sys.stderr)
        return
    attrs = {k: version[k] for k in VERSION_FIELDS if k in version}
    if attrs:
        body = {"data": {"type": "appStoreVersionLocalizations", "id": target["id"], "attributes": attrs}}
        r = requests.patch(f"{BASE}/appStoreVersionLocalizations/{target['id']}", headers=headers, json=body)
        if r.status_code in (200, 201):
            print(f"  [{locale}] version {vstr} PATCH OK: {', '.join(attrs)}")
        else:
            print(f"  !! [{locale}] version PATCH {r.status_code}: {r.text[:200]}", file=sys.stderr)


def validate(meta: dict) -> list[str]:
    errs: list[str] = []
    for loc in meta.get("managed_existing_localizations", []):
        info = {**loc.get("app_info", {}), **loc.get("version", {})}
        for field, limit in LIMITS.items():
            val = info.get(field)
            if isinstance(val, str) and len(val) > limit:
                errs.append(f"[{loc.get('locale')}] {field}: {len(val)} > {limit}")
    return errs


def main() -> int:
    apply = "--apply" in sys.argv
    meta = json.loads(META.read_text())
    errs = validate(meta)
    if errs:
        print("!! length violations:", file=sys.stderr)
        for e in errs:
            print("   " + e, file=sys.stderr)
        return 1
    print("OK: all fields within ASC length limits.")
    if not apply:
        print("dry-run（--apply で実際に同期）。")
        return 0

    # Apply path: requires creds + the ASC API client.
    for n in ("ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_PATH"):
        if not os.environ.get(n):
            print(f"!! set env {n} to --apply", file=sys.stderr)
            return 2
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    app_id = meta["app"]["app_id"]
    if not app_id or app_id.startswith("TODO"):
        print("!! metadata.json の app.app_id（adam id）が未記入", file=sys.stderr)
        return 2
    print(f"# syncing metadata to app {app_id} …")
    for loc in meta.get("managed_existing_localizations", []):
        sync_localization(loc, app_id, headers)
    print("（カテゴリ・年齢レーティング・App Privacy は ASC Web UI で手動）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
