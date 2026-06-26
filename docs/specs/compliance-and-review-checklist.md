# Yuzuri コンプライアンス & 出荷前レビューチェックリスト

> Mochiru レビューセッションで抽出した「毎回確認する再発項目」。
> 横断版は `~/.claude/plugins/freetokyo-ios/playbook/gotchas.md`。

## クラッシュ系（実バグの主因）
- [ ] `.sheet` / `.fullScreenCover` / `.popover` の中身に親の `@Environment`(observable store) を **明示再注入**したか
- [ ] `@Model`(SwiftData) に **ネスト Codable を直接保存していない**か（→ `Data`/JSON 保存）
- [ ] 保存→読み戻し→別タブ参照の**回帰テスト**があるか
- [ ] `ModelContainer` が移行失敗時に起動クラッシュしないフォールバックを持つか

## 横断安定性監査（grep/find で機械的に）
- [ ] `python3 scripts/audit_format_strings.py` が exit 0（`%@`×Int クラッシュ class なし）
- [ ] `try!` / `fatalError` / `as!` / 強制アンラップ `!` が app・engine にゼロ
- [ ] 配列添字に範囲ガード、ゼロ除算なし

## コンプラ文言（該当領域）
- [ ] `ComplianceTests` が緑（免責必須要素 + 禁止語不在）
- [ ] 「最適 / 推奨 / 必ず / 元本保証」等の断定語が UI/Web にない

## 審査却下の先回り（最頻出順）
- [ ] Paywall: 商品 **eager 取得**(`.task { await load() }`) + 購入失敗時ボタン無効化（2.1(a)）
- [ ] Paywall: **利用規約・プライバシーのリンク**を画面内に（3.1.2）
- [ ] IAP をそのバージョンの審査に**同梱**（2.1(b)・手動）
- [ ] レビュー用ビルドにクラッシュ/broken UI なし（2.1）
- [ ] Review Notes に「アカウント不要・オフライン・テスト手順・IAP は非消費型+復元」

## UI / 整合
- [ ] Web/メタの機能訴求が**実際に UI で操作可能**（過大記載=2.3.1 回避）
- [ ] 「開発中」表記をアプリ内・Web から排除、バージョンは Bundle から動的化
- [ ] デバッグ専用 UI は `#if DEBUG` ゲート
- [ ] アイコンは SF Symbol（絵文字の豆腐化回避）
- [ ] Chart 選択は `ScrollView` 内なら `chartOverlay`+`DragGesture(minimumDistance:0)`
