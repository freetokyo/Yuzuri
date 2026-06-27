#!/usr/bin/env python3
"""Create the Yuzuri non-consumable IAP (full unlock) via App Store Connect API.

Credentials from ENV ONLY: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH.
App id + product id come from scripts/yuzuri_metadata.json / constants below.

Creates (idempotent where possible):
  1. inAppPurchases (NON_CONSUMABLE)
  2. inAppPurchaseLocalizations (ja: name + description)
  3. inAppPurchasePriceSchedules (JPN base territory, ¥600 price point)

Note: review screenshot / "submit IAP with the build" は ASC Web UI で手動。
Usage: python3 scripts/asc_create_iap.py
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

META = Path(__file__).parent / "yuzuri_metadata.json"
BASE = "https://api.appstoreconnect.apple.com/v1"
BASE2 = "https://api.appstoreconnect.apple.com/v2"

PRODUCT_ID = "com.chen.yuzuri.fullunlock"
IAP_NAME = "ユズリ プレミアム"
IAP_LOC_NAME = "ユズリ プレミアム"
IAP_LOC_DESC = "PDF書き出し・暗号化バックアップ・秘匿モードを永続的に解放する買い切り購入です。サブスクなし。"
TERRITORY = "JPN"
TARGET_PRICE = "1500"  # ¥1,500 確定


def token() -> str:
    iss = os.environ["ASC_ISSUER_ID"]; kid = os.environ["ASC_KEY_ID"]; p8 = os.environ["ASC_PRIVATE_KEY_PATH"]
    now = int(time.time())
    return jwt.encode({"iss": iss, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      Path(p8).read_text(), algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def main() -> int:
    for n in ("ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_PATH"):
        if not os.environ.get(n):
            print(f"!! set env {n}", file=sys.stderr); return 2
    meta = json.loads(META.read_text())
    app_id = meta["app"]["app_id"]
    if not app_id or app_id.startswith("TODO"):
        print("!! app_id 未記入", file=sys.stderr); return 2
    h = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}

    # 1) 既存チェック → 無ければ作成
    existing = requests.get(f"{BASE}/apps/{app_id}/inAppPurchasesV2",
                            params={"filter[productId]": PRODUCT_ID}, headers=h).json().get("data", [])
    if existing:
        iap = existing[0]; iap_id = iap["id"]
        print(f"[exists] IAP {PRODUCT_ID} (id={iap_id}, state={iap['attributes'].get('state')})")
    else:
        body = {"data": {"type": "inAppPurchases",
                         "attributes": {"name": IAP_NAME, "productId": PRODUCT_ID,
                                        "inAppPurchaseType": "NON_CONSUMABLE"},
                         "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}
        r = requests.post(f"{BASE2}/inAppPurchases", headers=h, json=body)
        if r.status_code not in (200, 201):
            print(f"!! IAP create {r.status_code}: {r.text[:300]}", file=sys.stderr); return 1
        iap_id = r.json()["data"]["id"]
        print(f"[created] IAP {PRODUCT_ID} (id={iap_id})")

    # 2) ローカライズ（ja）
    locs = requests.get(f"{BASE}/inAppPurchases/{iap_id}/inAppPurchaseLocalizations",
                        headers=h).json().get("data", [])
    if any(l["attributes"].get("locale") == "ja" for l in locs):
        print("[exists] ja localization")
    else:
        body = {"data": {"type": "inAppPurchaseLocalizations",
                         "attributes": {"locale": "ja", "name": IAP_LOC_NAME, "description": IAP_LOC_DESC},
                         "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}}}}
        r = requests.post(f"{BASE}/inAppPurchaseLocalizations", headers=h, json=body)
        if r.status_code in (200, 201):
            print("[created] ja localization")
        else:
            print(f"!! localization {r.status_code}: {r.text[:300]}", file=sys.stderr)

    # 3) 価格（¥600, JPN ベース）
    sched = requests.get(f"{BASE}/inAppPurchases/{iap_id}/inAppPurchasePriceSchedule", headers=h)
    if sched.status_code == 200 and sched.json().get("data"):
        print("[exists] price schedule（既設定。変更は ASC Web UI 推奨）")
        return 0

    pps = requests.get(f"{BASE2}/inAppPurchases/{iap_id}/pricePoints",
                       params={"filter[territory]": TERRITORY, "limit": 200}, headers=h).json().get("data", [])
    point = next((p for p in pps if p["attributes"].get("customerPrice") == TARGET_PRICE), None)
    if not point:
        avail = sorted({p["attributes"].get("customerPrice") for p in pps}, key=lambda x: float(x or 0))
        print(f"!! ¥{TARGET_PRICE} の price point が無い。候補: {avail[:20]}", file=sys.stderr); return 1
    temp = "${price1}"
    body = {
        "data": {"type": "inAppPurchasePriceSchedules",
                 "relationships": {
                     "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                     "baseTerritory": {"data": {"type": "territories", "id": TERRITORY}},
                     "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": temp}]}}},
        "included": [{"type": "inAppPurchasePrices", "id": temp,
                      "attributes": {"startDate": None},
                      "relationships": {"inAppPurchasePricePoint": {
                          "data": {"type": "inAppPurchasePricePoints", "id": point["id"]}}}}]}
    r = requests.post(f"{BASE}/inAppPurchasePriceSchedules", headers=h, json=body)
    if r.status_code in (200, 201):
        print(f"[created] price schedule ¥{TARGET_PRICE} (JPN base)")
    else:
        print(f"!! price schedule {r.status_code}: {r.text[:300]}", file=sys.stderr); return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
