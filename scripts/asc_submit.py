#!/usr/bin/env python3
"""Drive the API-possible parts of Yuzuri's App Store submission.

Credentials from ENV ONLY: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH.

Steps (selectable via argv; default = all prep, NO final submit):
  build      … 最新 VALID ビルドを version に紐付け
  agerating  … 年齢レーティング宣言を全 NONE（4+）に設定
  shots      … スクショを version localization へアップロード（6.9" + 13"）
  iapshot    … IAP 審査用スクショをアップロード
  submit     … reviewSubmission を作成し version + IAP を同梱して提出（App Privacy 等が未完だと失敗）

Usage:
  python3 scripts/asc_submit.py build agerating shots iapshot      # 提出前まで
  python3 scripts/asc_submit.py submit                             # 提出（手動ゲート通過後）
"""
from __future__ import annotations

import hashlib
import os
import sys
import time
from pathlib import Path

import jwt
import requests

B = "https://api.appstoreconnect.apple.com/v1"
import json as _json
APP = _json.loads((Path(__file__).parent / "yuzuri_metadata.json").read_text())["app"]["app_id"]
IAP_PRODUCT = "com.chen.yuzuri.fullunlock"
ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "build/screenshots"

IPHONE_69 = "APP_IPHONE_67"          # 6.9"/6.7" 共通スロット（1320x2868 を受理）
IPAD_13 = "APP_IPAD_PRO_3GEN_129"    # 12.9"/13" スロット

AGE_RATING_NONE = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "violenceRealistic": "NONE",
    "unrestrictedWebAccess": False,
    "gambling": False,
}


def token() -> str:
    kid = os.path.basename(os.environ["ASC_PRIVATE_KEY_PATH"]).replace("AuthKey_", "").replace(".p8", "")
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1200,
                       "aud": "appstoreconnect-v1"},
                      Path(os.environ["ASC_PRIVATE_KEY_PATH"]).read_text(),
                      algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def H() -> dict:
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


# --- 共通ルックアップ -------------------------------------------------------

def editable_version(h):
    vs = requests.get(f"{B}/apps/{APP}/appStoreVersions", headers=h).json().get("data", [])
    for v in vs:
        if v["attributes"].get("appStoreState") in (
            "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
            return v
    return vs[0] if vs else None


def ja_localization(h, version_id):
    locs = requests.get(f"{B}/appStoreVersions/{version_id}/appStoreVersionLocalizations",
                        headers=h).json().get("data", [])
    return next((l for l in locs if l["attributes"].get("locale") == "ja"), locs[0] if locs else None)


def iap_id(h):
    data = requests.get(f"{B}/apps/{APP}/inAppPurchasesV2",
                        params={"filter[productId]": IAP_PRODUCT}, headers=h).json().get("data", [])
    return data[0]["id"] if data else None


# --- ステップ ---------------------------------------------------------------

def step_build(h):
    builds = requests.get(f"{B}/builds", params={"filter[app]": APP, "sort": "-uploadedDate", "limit": 5},
                          headers=h).json().get("data", [])
    valid = next((b for b in builds if b["attributes"].get("processingState") == "VALID"
                  and not b["attributes"].get("expired")), None)
    if not valid:
        print("  build: VALID なビルドが無い（処理中の可能性）"); return
    v = editable_version(h)
    body = {"data": {"type": "builds", "id": valid["id"]}}
    r = requests.patch(f"{B}/appStoreVersions/{v['id']}/relationships/build", headers=h, json=body)
    print(f"  build attach -> {r.status_code} (build {valid['attributes'].get('version')})"
          + ("" if r.status_code in (200, 204) else f" {r.text[:200]}"))


def step_agerating(h):
    ai = requests.get(f"{B}/apps/{APP}/appInfos", headers=h).json().get("data", [])[0]
    decl = requests.get(f"{B}/appInfos/{ai['id']}/ageRatingDeclaration", headers=h).json().get("data")
    if not decl:
        print("  agerating: declaration が見つからない"); return
    body = {"data": {"type": "ageRatingDeclarations", "id": decl["id"], "attributes": AGE_RATING_NONE}}
    r = requests.patch(f"{B}/ageRatingDeclarations/{decl['id']}", headers=h, json=body)
    print(f"  agerating -> {r.status_code} (全 NONE = 4+)"
          + ("" if r.status_code == 200 else f" {r.text[:200]}"))


def _get_or_create_screenshot_set(h, loc_id, display_type):
    sets = requests.get(f"{B}/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
                        headers=h).json().get("data", [])
    found = next((s for s in sets if s["attributes"].get("screenshotDisplayType") == display_type), None)
    if found:
        return found["id"]
    body = {"data": {"type": "appScreenshotSets",
                     "attributes": {"screenshotDisplayType": display_type},
                     "relationships": {"appStoreVersionLocalization":
                                       {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}}
    r = requests.post(f"{B}/appScreenshotSets", headers=h, json=body)
    r.raise_for_status()
    return r.json()["data"]["id"]


def _upload_one(h, set_id, path: Path):
    data = path.read_bytes()
    # 1) reserve
    body = {"data": {"type": "appScreenshots",
                     "attributes": {"fileName": path.name, "fileSize": len(data)},
                     "relationships": {"appScreenshotSet":
                                       {"data": {"type": "appScreenshotSets", "id": set_id}}}}}
    r = requests.post(f"{B}/appScreenshots", headers=h, json=body)
    if r.status_code not in (200, 201):
        print(f"    reserve {path.name} -> {r.status_code} {r.text[:200]}"); return False
    obj = r.json()["data"]
    sid = obj["id"]
    # 2) upload chunks
    for op in obj["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        hdrs = {hh["name"]: hh["value"] for hh in op.get("requestHeaders", [])}
        up = requests.request(op["method"], op["url"], headers=hdrs, data=chunk)
        if up.status_code not in (200, 201):
            print(f"    upload chunk {path.name} -> {up.status_code}"); return False
    # 3) commit
    md5 = hashlib.md5(data).hexdigest()
    patch = {"data": {"type": "appScreenshots", "id": sid,
                      "attributes": {"uploaded": True, "sourceFileChecksum": md5}}}
    pr = requests.patch(f"{B}/appScreenshots/{sid}", headers=H(), json=patch)
    ok = pr.status_code == 200
    print(f"    {path.name} -> {'OK' if ok else pr.status_code}" + ("" if ok else f" {pr.text[:160]}"))
    return ok


def step_shots(h):
    v = editable_version(h)
    loc = ja_localization(h, v["id"])
    plan = [
        (IPHONE_69, sorted((SHOTS / "6.9inch").glob("*.png"))),
        (IPAD_13, sorted((SHOTS / "13inch").glob("*.png"))),
    ]
    for disp, files in plan:
        if not files:
            print(f"  shots {disp}: ファイル無し"); continue
        set_id = _get_or_create_screenshot_set(h, loc["id"], disp)
        existing = requests.get(f"{B}/appScreenshotSets/{set_id}/appScreenshots",
                                headers=h).json().get("data", [])
        if existing:
            print(f"  shots {disp}: 既に {len(existing)} 枚あり（スキップ）"); continue
        print(f"  shots {disp}: {len(files)} 枚アップロード")
        for f in files:
            _upload_one(h, set_id, f)


def step_iapshot(h):
    iid = iap_id(h)
    if not iid:
        print("  iapshot: IAP が見つからない"); return
    # 既存チェック
    cur = requests.get(f"{B}/inAppPurchases/{iid}/appStoreReviewScreenshot", headers=h)
    if cur.status_code == 200 and cur.json().get("data"):
        print("  iapshot: 既にアップロード済み（スキップ）"); return
    # 設定画面（プレミアム解放導線）を IAP 審査スクショに流用
    path = SHOTS / "6.9inch/03_settings.png"
    if not path.is_file():
        print("  iapshot: 設定スクショが無い"); return
    data = path.read_bytes()
    body = {"data": {"type": "inAppPurchaseAppStoreReviewScreenshots",
                     "attributes": {"fileName": path.name, "fileSize": len(data)},
                     "relationships": {"inAppPurchaseV2":
                                       {"data": {"type": "inAppPurchases", "id": iid}}}}}
    r = requests.post(f"{B}/inAppPurchaseAppStoreReviewScreenshots", headers=h, json=body)
    if r.status_code not in (200, 201):
        print(f"  iapshot reserve -> {r.status_code} {r.text[:200]}"); return
    obj = r.json()["data"]; sid = obj["id"]
    for op in obj["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        hdrs = {hh["name"]: hh["value"] for hh in op.get("requestHeaders", [])}
        requests.request(op["method"], op["url"], headers=hdrs, data=chunk)
    md5 = hashlib.md5(data).hexdigest()
    pr = requests.patch(f"{B}/inAppPurchaseAppStoreReviewScreenshots/{sid}", headers=H(),
                        json={"data": {"type": "inAppPurchaseAppStoreReviewScreenshots", "id": sid,
                                       "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    print(f"  iapshot -> {'OK' if pr.status_code == 200 else pr.status_code}"
          + ("" if pr.status_code == 200 else f" {pr.text[:160]}"))


def step_submit(h):
    v = editable_version(h)
    iid = iap_id(h)
    # 既存の open submission を探す
    subs = requests.get(f"{B}/reviewSubmissions",
                        params={"filter[app]": APP, "filter[state]": "READY_FOR_REVIEW,COMPLETING"},
                        headers=h).json().get("data", [])
    sub = None
    open_subs = requests.get(f"{B}/reviewSubmissions", params={"filter[app]": APP}, headers=h).json().get("data", [])
    sub = next((s for s in open_subs if s["attributes"].get("state") in
                ("READY_FOR_REVIEW", "COMPLETING", "UNRESOLVED_ISSUES")), None)
    if not sub:
        body = {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                         "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}}
        r = requests.post(f"{B}/reviewSubmissions", headers=h, json=body)
        if r.status_code not in (200, 201):
            print(f"  submit: reviewSubmission 作成 -> {r.status_code} {r.text[:300]}"); return
        sub = r.json()["data"]
    sub_id = sub["id"]
    print(f"  reviewSubmission id={sub_id} state={sub['attributes'].get('state')}")
    # items: version + IAP
    items = requests.get(f"{B}/reviewSubmissions/{sub_id}/items", headers=h).json().get("data", [])
    have_types = set()
    for it in items:
        rel = requests.get(f"{B}/reviewSubmissionItems/{it['id']}", headers=h).json()
        have_types |= set(rel.get("data", {}).get("relationships", {}).keys())
    def add_item(rel_name, rtype, rid):
        body = {"data": {"type": "reviewSubmissionItems",
                         "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                                           rel_name: {"data": {"type": rtype, "id": rid}}}}}
        r = requests.post(f"{B}/reviewSubmissionItems", headers=h, json=body)
        print(f"    add {rel_name} -> {r.status_code}" + ("" if r.status_code in (200, 201) else f" {r.text[:200]}"))
    if not items:
        add_item("appStoreVersion", "appStoreVersions", v["id"])
        if iid:
            add_item("inAppPurchaseV2", "inAppPurchases", iid)
    else:
        print(f"    既存アイテム {len(items)} 件")
    # submit
    r = requests.patch(f"{B}/reviewSubmissions/{sub_id}", headers=h,
                       json={"data": {"type": "reviewSubmissions", "id": sub_id,
                                      "attributes": {"submitted": True}}})
    if r.status_code == 200:
        print(f"  SUBMIT -> OK (state={r.json()['data']['attributes'].get('state')})")
    else:
        print(f"  SUBMIT -> {r.status_code}: {r.text[:500]}")


STEPS = {"build": step_build, "agerating": step_agerating, "shots": step_shots,
         "iapshot": step_iapshot, "submit": step_submit}


def main() -> int:
    for n in ("ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_PATH"):
        if not os.environ.get(n):
            print(f"!! set env {n}", file=sys.stderr); return 2
    args = [a for a in sys.argv[1:] if a in STEPS]
    if not args:
        args = ["build", "agerating", "shots", "iapshot"]   # 既定: 提出前まで
    h = H()
    for a in args:
        print(f"# {a}")
        STEPS[a](h)
    return 0


if __name__ == "__main__":
    sys.exit(main())
