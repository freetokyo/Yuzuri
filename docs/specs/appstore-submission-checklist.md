# Yuzuri App Store 提出チェックリスト

## メタデータ（length 制限を `asc_sync_metadata.py` が検証）
- [ ] name ≤30 / subtitle ≤30 / keywords ≤100 / promotionalText ≤170 / description ≤4000
- [ ] `scripts/yuzuri_metadata.json` を記入し `python3 scripts/asc_sync_metadata.py`（dry-run）が OK
- [ ] カテゴリ設定（App 本体 PATCH。relationships endpoint は 403）
- [ ] スクリーンショット: 6.9" iPhone ×3、13" iPad ×2

## ASC エンティティ作成順
1. `python3 scripts/asc_create_bundle_id.py`（Bundle ID は API 可）
2. **App 本体は ASC Web UI で作成**（API は 403）→ adam id を PROJECT_CONTEXT.md へ
3. IAP `com.chen.yuzuri.fullunlock`（非消費型）を作成
4. （CloudKit 使用時）コンテナは Xcode/Developer Portal で登録（API は 404）

## ビルド & アップロード（ヘッドレス）
- [ ] build 番号 +1 → archive → export → `altool --upload-app`
- [ ] Distribution 証明書が無くても `-allowProvisioningUpdates` + ASC API キーで自動発行・アップロード可

## 手動のみ（API 不可）
- [ ] 年齢レーティング
- [ ] App Privacy（データ収集なしを申告）
- [ ] IAP を審査に同梱（最頻出の却下原因）
- [ ] 暗号化申告（`ITSAppUsesNonExemptEncryption=NO` を Info に設定済み）

## 連絡先・ノート（API 可）
- [ ] Copyright `2026 CHEN YANGLI`
- [ ] App Review 連絡先 / Review Notes（アカウント不要・オフライン・IAP 非消費型+復元）
