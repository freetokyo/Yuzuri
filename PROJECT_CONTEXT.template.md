# PROJECT_CONTEXT — Yuzuri（ローカル専用・gitignore）

> このファイルはコピーして `PROJECT_CONTEXT.md` にし、各値を記入する。
> `.gitignore` 済み。**秘密鍵（.p8）本体は絶対にここへ貼らない** — パスのみ。

## App Store Connect

- Bundle ID: `com.chen.yuzuri`
- App (adam) ID: `（ASC Web UI で App 本体を作成後に記入。API では作成不可 = 403）`
- Apple Team ID: `QM4TX6386A`
- IAP product id（買い切り）: `com.chen.yuzuri.fullunlock`

## ASC API 認証（環境変数で渡す。ここには値を書かない）

```bash
export ASC_ISSUER_ID=...        # 中央 _tools/analytics/config.py と同一
export ASC_KEY_ID=...
export ASC_PRIVATE_KEY_PATH="$HOME/AppleKey/AuthKey_<KEY_ID>.p8"   # リポジトリ外
```

## ステータス / ブロッカー

- [ ] 法務・コンプライアンスレビュー
- [ ] アイコン確定
- [ ] 価格確定
- [ ] App Privacy / 年齢レーティング（ASC Web UI で手動）
