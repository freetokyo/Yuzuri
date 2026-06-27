#!/usr/bin/env python3
"""ユズリ — ASC の API 更新可能な提出項目をまとめて反映（冪等・提出はしない）。

認証は ENV のみ: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH。

反映する項目（すべて API 可。App Privacy のみ Web UI 手動で別途）:
  [1] カテゴリ        primary=UTILITIES, secondary=PRODUCTIVITY（appInfos 本体 PATCH）
  [2] 年齢レーティング all NONE / booleans False → 4+（2025 新フィールド対応）
  [3] 審査連絡先      contact + Review Notes（appStoreReviewDetails）
  [4] copyright       appStoreVersions.copyright
  [5] コンテンツ権利   apps.contentRightsDeclaration = DOES_NOT_USE_THIRD_PARTY_CONTENT
  [6] 無料価格        appPriceSchedules（customerPrice=0, JPN base）
  [7] ビルド紐付け     最新 VALID build を version へ（未処理ならスキップ）

Usage: python3 scripts/asc_finalize.py
"""
from __future__ import annotations
import json, os, sys, time
from pathlib import Path
import jwt, requests

B = "https://api.appstoreconnect.apple.com/v1"
import json as _json
APP = _json.loads((Path(__file__).parent / "yuzuri_metadata.json").read_text())["app"]["app_id"]
LOCALE = "ja"
COPYRIGHT = "2026 CHEN YANGLI"
PRIMARY_CATEGORY = "UTILITIES"
SECONDARY_CATEGORY = "PRODUCTIVITY"

CONTACT = {
    "contactFirstName": "CHEN",
    "contactLastName": "YANGLI",
    "contactPhone": "+81-80-5011-6678",
    "contactEmail": "freetokyo2020@yahoo.co.jp",
    "demoAccountRequired": False,
    "notes": (
        "【アプリ概要】\n"
        "ユズリは完全オフラインの終活ノートアプリです。資産・医療・葬儀・家族へのメッセージ等を端末内のみに保存し、PDFとして書き出せます。アカウント不要・データ収集なし。\n\n"
        "【動作テスト手順】\n"
        "1. 起動 → オンボーディング画面（免責確認）を「確認して始める」で閉じる。\n"
        "2. Face ID / Touch ID 認証（シミュレータでは自動通過）→ ホーム画面が表示される。\n"
        "3. カテゴリ（例：「基本情報」）をタップ → 項目に文字を入力 → ホームに戻り記入率が上昇することを確認。\n"
        "4. 「書き出し」タブ → 「プレミアムを解放」ボタン → IAP シートが表示される（審査用アカウント不要・テスト課金可）。\n"
        "5. IAP 購入後 → 「安全版を作成」ボタンが有効になり PDF が生成・共有シートが表示される。\n"
        "6. 設定 → 「暗号化バックアップ」→ パスフレーズを入力して書き出し・取り込みが動作する。\n\n"
        "【データ・プライバシー】\n"
        "- すべて端末内処理（SwiftData ローカル保存）。外部サーバへの送信・通信なし（URLSession 等を一切使用していない）。\n"
        "- アカウント不要・完全オフライン（機内モードで全機能動作）。\n"
        "- App Privacy は「データを収集しません」（Data Not Collected）。\n\n"
        "【課金（IAP）】\n"
        "- 無料：全カテゴリの記入・閲覧・カスタム項目・ロック機能。\n"
        "- 買い切り（非消費型）com.chen.yuzuri.fullunlock ¥1,500 でPDF書き出し・暗号化バックアップ・秘匿モードを解放。\n"
        "- 設定 → 「購入を復元」で復元可能。\n\n"
        "【免責】\n"
        "本アプリは情報の記録・整理ツールです。エンディングノートは遺言書ではなく法的効力はありません。法律・税務・医療の助言は行いません。"
    ),
}

AGE_RATING = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE", "contests": "NONE",
    "gamblingSimulated": "NONE", "gunsOrOtherWeapons": "NONE",
    "horrorOrFearThemes": "NONE", "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE", "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE", "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE", "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "advertising": False, "ageAssurance": False, "gambling": False,
    "healthOrWellnessTopics": False, "lootBox": False, "messagingAndChat": False,
    "parentalControls": False, "unrestrictedWebAccess": False, "userGeneratedContent": False,
}

_tok = None
def H():
    global _tok
    if _tok is None:
        now = int(time.time())
        _tok = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1200,
                           "aud": "appstoreconnect-v1"},
                          Path(os.environ["ASC_PRIVATE_KEY_PATH"]).read_text(),
                          algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})
    return {"Authorization": f"Bearer {_tok}", "Content-Type": "application/json"}


def editable_app_info():
    data = requests.get(f"{B}/apps/{APP}/appInfos", headers=H()).json().get("data", [])
    states = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "METADATA_REJECTED", "REJECTED"}
    return next((a for a in data if a["attributes"].get("state") in states), data[0])


def editable_version():
    data = requests.get(f"{B}/apps/{APP}/appStoreVersions?limit=10", headers=H()).json().get("data", [])
    states = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "METADATA_REJECTED", "REJECTED", "WAITING_FOR_REVIEW"}
    return next((v for v in data if v["attributes"].get("appStoreState") in states), data[0])


def step_categories(ai_id):
    body = {"data": {"type": "appInfos", "id": ai_id, "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": PRIMARY_CATEGORY}},
        "secondaryCategory": {"data": {"type": "appCategories", "id": SECONDARY_CATEGORY}}}}}
    r = requests.patch(f"{B}/appInfos/{ai_id}", headers=H(), json=body)
    print(f"[1] categories {PRIMARY_CATEGORY}/{SECONDARY_CATEGORY}:", "OK" if r.status_code in (200, 204) else f"{r.status_code} {r.text[:160]}")


def step_age_rating(ai_id):
    decl = requests.get(f"{B}/appInfos/{ai_id}/ageRatingDeclaration", headers=H()).json().get("data")
    if not decl:
        print("[2] age rating: declaration なし"); return
    body = {"data": {"type": "ageRatingDeclarations", "id": decl["id"], "attributes": AGE_RATING}}
    r = requests.patch(f"{B}/ageRatingDeclarations/{decl['id']}", headers=H(), json=body)
    print("[2] age rating 4+:", "OK" if r.status_code in (200, 204) else f"{r.status_code} {r.text[:160]}")


def step_review_detail(v_id):
    cur = requests.get(f"{B}/appStoreVersions/{v_id}/appStoreReviewDetail", headers=H())
    existing = cur.json().get("data") if cur.status_code == 200 else None
    if existing:
        body = {"data": {"type": "appStoreReviewDetails", "id": existing["id"], "attributes": CONTACT}}
        r = requests.patch(f"{B}/appStoreReviewDetails/{existing['id']}", headers=H(), json=body)
    else:
        body = {"data": {"type": "appStoreReviewDetails", "attributes": CONTACT,
                         "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": v_id}}}}}
        r = requests.post(f"{B}/appStoreReviewDetails", headers=H(), json=body)
    print("[3] review detail:", "OK" if r.status_code in (200, 201, 204) else f"{r.status_code} {r.text[:160]}")


def step_copyright(v_id):
    body = {"data": {"type": "appStoreVersions", "id": v_id, "attributes": {"copyright": COPYRIGHT}}}
    r = requests.patch(f"{B}/appStoreVersions/{v_id}", headers=H(), json=body)
    print(f"[4] copyright '{COPYRIGHT}':", "OK" if r.status_code in (200, 204) else f"{r.status_code} {r.text[:160]}")


def step_content_rights():
    body = {"data": {"type": "apps", "id": APP,
                     "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}}
    r = requests.patch(f"{B}/apps/{APP}", headers=H(), json=body)
    print("[5] contentRights DOES_NOT_USE_THIRD_PARTY_CONTENT:", "OK" if r.status_code in (200, 204) else f"{r.status_code} {r.text[:160]}")


def step_free_price():
    # 既に price schedule があるか。
    cur = requests.get(f"{B}/apps/{APP}/appPriceSchedule", headers=H())
    if cur.status_code == 200 and cur.json().get("data"):
        print("[6] free price: 既に price schedule あり（スキップ）"); return
    pts = requests.get(f"{B}/apps/{APP}/appPricePoints",
                       headers=H(), params={"filter[territory]": "JPN", "limit": 200}).json().get("data", [])
    zero = next((p for p in pts if p["attributes"].get("customerPrice") == "0"), None)
    if not zero:
        print("[6] free price: ¥0 の price point が見つからず"); return
    body = {"data": {"type": "appPriceSchedules",
                     "relationships": {
                         "app": {"data": {"type": "apps", "id": APP}},
                         "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                         "manualPrices": {"data": [{"type": "appPrices", "id": "${price0}"}]}}},
            "included": [{"type": "appPrices", "id": "${price0}",
                          "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": zero["id"]}}}}]}
    r = requests.post(f"{B}/appPriceSchedules", headers=H(), json=body)
    print("[6] free price (¥0, JPN base):", "OK" if r.status_code in (200, 201) else f"{r.status_code} {r.text[:160]}")


def step_link_build(v_id):
    builds = requests.get(f"{B}/builds",
                          headers=H(), params={"filter[app]": APP, "limit": 20, "sort": "-uploadedDate"}).json().get("data", [])
    valid = [b for b in builds if b["attributes"].get("processingState") == "VALID" and not b["attributes"].get("expired")]
    if not valid:
        print("[7] build link: VALID build なし（処理中。後で再実行）"); return
    bid = valid[0]["id"]
    body = {"data": {"type": "builds", "id": bid}}
    r = requests.patch(f"{B}/appStoreVersions/{v_id}/relationships/build", headers=H(), json=body)
    print(f"[7] build link (id={bid}):", "OK" if r.status_code in (200, 204) else f"{r.status_code} {r.text[:160]}")


def main():
    for n in ("ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_PATH"):
        if not os.environ.get(n):
            print(f"!! set env {n}", file=sys.stderr); return 2
    ai = editable_app_info(); v = editable_version()
    print(f"# app={APP} appInfo={ai['id']} version={v['id']} ({v['attributes'].get('versionString')})")
    step_categories(ai["id"])
    step_age_rating(ai["id"])
    step_review_detail(v["id"])
    step_copyright(v["id"])
    step_content_rights()
    step_free_price()
    step_link_build(v["id"])
    print("# App Privacy（データ収集なし）は ASC Web UI で手動 → 公開後に提出可")
    return 0


if __name__ == "__main__":
    sys.exit(main())
