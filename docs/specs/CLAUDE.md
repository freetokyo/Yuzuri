# CLAUDE.md — ユズリ（オフライン終活ノート）実装ブリーフ v1.1

> リポジトリ直下に `CLAUDE.md` として配置。Claude Code はこの方針に従って実装する。
> 出典PRD：`ユズリ_PRD_v1.2.md`（仕様の正典。齟齬時はPRDを優先し、本書を更新）。

## 0. 最重要原則（絶対遵守）

1. **完全オフライン／非送信**：ネットワークアクセスを一切実装しない。`URLSession`等の通信コード、解析SDK、広告SDKを入れない。App Transport Securityに依存する処理を作らない。**サードパーティSDKは使用禁止（Apple純正のみ）**。
2. **データはユーザーの所有物**：保存は端末ローカル（SwiftData）。バックアップ／持ち出しは「PDF」と「暗号化アーカイブ」を介してユーザー操作でのみ行う。自動クラウド同期はMVPで実装しない。
3. **買い切り・広告ゼロ・トラッキングゼロ**：StoreKit 2の非消費型1回購入のみ。
4. **多言語2層**：UI文字列＝String Catalog／項目セット＝ロケール別テンプレート（データ）。コードに項目ラベルをハードコードしない。
5. **法的に踏み込まない**：情報の記録のみ。法的・税務的結論や助言を出すUI・文言を作らない。免責を表示する。

## 1. 技術スタック / 環境

- Swift / SwiftUI、**配信ターゲット iOS 18.0／ビルドSDK iOS 26**（2026/4/28以降の必須要件。Xcodeは iOS 26 SDK でビルドし、Deployment Target を 18.0 にする）
- 永続化：SwiftData（ローカルのみ、CloudKit不使用）
- 認証：LocalAuthentication（Face ID / Touch ID）＋独自パスコード
- 暗号：CryptoKit（必要に応じ Secure Enclave）
- PDF：PDFKit
- 課金：StoreKit 2（非消費型、¥1,500）
- ローカライズ：String Catalog（.xcstrings）＋ロケール別項目テンプレJSON
- 共通基盤：FreetokyoKit（既存の共通UI/ユーティリティを流用）
- **Info.plist にネットワーク用途のキーを追加しない。広告/解析/課金以外のエンタイトルメントを追加しない。**
- **プライバシー**：プライバシーラベルは「Data Not Collected」。プライバシーポリシーURLを掲示（GitHub Pages）。アカウント機能なし＝Sign in with Apple等の対象外。

## 2. プロジェクト構成（案）

```
Yuzuri/                      # アプリターゲット
  App/                       # エントリ、ルートビュー、ロック制御
  Features/
    Home/                    # 記入率ダッシュボード＋カテゴリ一覧
    Category/                # カテゴリ→項目リスト
    EntryEditor/             # 項目編集（構造化＋フリーテキスト＋秘匿）
    CustomItem/              # カスタム項目の追加・並べ替え
    Export/                  # PDF / 暗号化アーカイブ
    Settings/                # ロック方針・バックアップ・言語・削除
    Paywall/                 # 買い切りアンロック
  Resources/
    Localizable.xcstrings    # UI文字列（ja, en, …）
    Templates/
      template.base.json     # 共通ベース項目
      template.ja.json       # 日本語上書き
      template.en.json       # 汎用英語上書き
YuzuriKit/                   # Swift Package（ロジック分離・テスト容易化）
  Models/                    # SwiftData @Model
  Localization/              # テンプレローダ、ロケール解決
  Security/                  # 暗号・鍵・ロック
  PDF/                       # PDF生成
  Archive/                   # 暗号化アーカイブ入出力
  Store/                     # StoreKit ラッパ
Tests/
```

## 3. データモデル（SwiftData）

ラベルはモデルに持たせず、`categoryKey` / `fieldKey` でテンプレ＋String Catalogから解決（多言語のため）。

```swift
@Model final class OwnerProfile { /* 本人基本情報。実質シングルトン */ }

@Model final class NoteEntry {
    var categoryKey: String          // 例 "assets.bank"
    var title: String
    var structuredValues: [String:String]  // fieldKey: value（非秘匿のみ）
    var freeText: String
    var status: EntryStatus          // .empty / .inProgress / .done
    var isSensitive: Bool
    var isCustom: Bool
    var sortOrder: Int
    var updatedAt: Date
    @Relationship var sensitive: SensitiveBlob?
}

@Model final class CustomField {     // カスタム項目定義（6.8）
    var label: String                // 利用者入力の生文字列（翻訳対象外）
    var fieldType: FieldType         // text/multiline/date/choice/sensitive
    var isSensitive: Bool
    var sortOrder: Int
}

@Model final class SensitiveBlob {   // 秘匿データ：暗号化ペイロード
    var ciphertext: Data             // CryptoKitで暗号化
    var nonce: Data
}

@Model final class ContactPerson { var name: String; var relation: String; var phone: String; var notify: Bool }
@Model final class FarewellMessage { var recipientLabel: String; var body: String }
@Model final class DocumentLocation { var docType: String; var locationHint: String }
@Model final class AppSettings { var localeOverride: String?; var lockTimeout: Int; var pdfIncludesSensitiveDefault: Bool /* false */ }
```

- 保存データは**言語非依存**（キー＋値）。表示言語変更後も入力は保持。
- 専用エンティティ（BankAccount等）には分けず、`NoteEntry`の汎用方式でMVPを軽量化。

## 4. ローカライズ / 項目テンプレ

- **A層（UI文字列）**：String Catalog。`Text("home.title")` 等のキー参照。
- **B層（項目テンプレ）**：`template.base.json` ＋ `template.<locale>.json` をマージしてロード。
  - テンプレ要素：`categoryKey`, `fieldKey[]`, ラベル参照キー, 並び順, `defaultSensitive`, `disclaimerKey`。
  - JP：本籍・香典・宗派 等を含む。EN：beneficiary / living will / POA保管場所 等へ差し替え、JP固有項目は出さない。
- 言語追加＝ String Catalog翻訳追加 ＋（必要なら）テンプレ上書きJSON追加。**コード変更なし**で増やせる構造にする。
- MVPは ja / en。en は「汎用英語版＋『お住まいの国の専門家へ確認を』」の免責で特定法域を回避。

## 5. セキュリティ / ロック

- 起動時・バックグラウンド復帰時（タイムアウト設定可）に生体認証 → フォールバックでパスコード。
- 機微情報（6.2）は二段：
  - 既定「ありかモード」＝保管場所のみ記録。
  - 任意「秘匿モード」＝再認証のうえ `SensitiveBlob` にCryptoKitで暗号化保存。入力時にリスク警告。
- PDF/アーカイブ書き出し時、秘匿項目は既定で**伏せる**（含めるは明示操作）。

## 6. PDF書き出し（中核）

- カテゴリ単位／全体。表紙＋目次＋「書類のありか一覧」＋（任意）緊急医療カード1枚。
- 「秘匿を含めない安全版」と「全部入り版」を選択。印刷・共有可能。
- 大きめフォント・高コントラスト（高齢の読み手を想定）。

## 7. バックアップ / アーカイブ

- パスフレーズ付き暗号化アーカイブを書き出し、ユーザーが Files / iCloud Drive へ保存。再取り込みで完全復元。
- 「アプリが将来使えなくなっても、PDFと暗号化アーカイブが手元に残る」を満たす。

## 8. 課金（StoreKit 2）

- 無料：全カテゴリの記入・閲覧・編集・ロック・カスタム項目を無制限。
- 買い切り（非消費型、**¥1,500確定**）でアンロック：**PDF書き出し＋暗号化アーカイブ＋（任意）秘匿モード**。
- ペイウォールでアンロック内容を明示（審査2.3.2＝有料機能の透明性）。
- サブスクは実装しない。リストア対応必須。

## 9. アクセシビリティ / UX

- Dynamic Type、VoiceOver、十分なコントラスト、大きいタップ領域、平易な文言。
- 英語の語長増にも崩れないレイアウト。
- オンボーディングは最小（非送信の明示 → ロック設定 → 完了）。

## 10. マイルストーン（受け入れ条件付き）

| M | 内容 | 受け入れ条件 |
|---|---|---|
| M0 | 雛形・パッケージ分割・テンプレローダ | base+ja マージで日本語カテゴリ一覧が描画される。ネットワークコードが存在しない（grep確認） |
| M1 | 記入フロー＋SwiftData永続化＋状態管理 | 全カテゴリで入力・保存・再起動後の保持。記入率が更新される |
| M2 | ロック＋秘匿モード（暗号化） | 生体認証ロック動作。秘匿項目が暗号化保存され、復号表示に再認証が必要 |
| M3 | PDF書き出し（安全版/全部入り） | 表紙＋目次付きPDFを生成、秘匿は既定で伏せる |
| M4 | 暗号化アーカイブ入出力 | 書き出し→取り込みで完全復元 |
| M5 | カスタム項目（追加・並べ替え） | 任意項目を追加しPDF/アーカイブに反映 |
| M6 | 多言語 en（UI＋テンプレ汎用版＋免責） | 端末言語/設定で en に切替、項目が現地版に差し替わる |
| M7 | 課金（買い切り＋リストア） | アンロックでPDF/アーカイブ解放、リストア動作 |
| M8 | 免責/法的文言・アクセシビリティ仕上げ | 免責表示、Dynamic Type/VoiceOver確認 |

## 11. MVPスコープ外（実装しない）

自動iCloud同期、家族共有・没後通知、OCR取り込み、Foundation Models、写真/動画/音声添付、Android、iPad最適化、ASC全言語（en以外）。※Phase 2以降（PRD第15章）。

## 12. コーディング指針

- Apple純正フレームワークのみ。サードパーティ依存ゼロ。
- ロジックは `YuzuriKit` に寄せ、ビューは薄く。ユニットテストを付ける（特に暗号・テンプレマージ・PDF・アーカイブ往復）。
- 文言・項目をハードコードしない（キー参照）。
- 破壊的操作（全削除等）は確認＋取り消し導線。

## 13. 【要確認】（PRDと同期）

1. 商標：J-PlatPat「ユズリ」確定照会（区分9／11C01）。en版ブランド名。
2. 秘匿モードをMVPに含めるか（含める前提で設計、最終判断待ち）。
3. 価格：¥1,500確定（ローンチ後に±調整を検討）。残：秘匿モードを無料に含めるか。
4. en を「汎用英語」か「en-US特化」か。各ロケール免責のレビュー体制。
5. カスタム項目の上限・既定項目の非表示可否。
6. App Store審査（医療/法律表現）の提出直前再確認。
7. プライバシーポリシー掲示・Data Not Collectedラベル・iOS 26 SDKビルド設定。
