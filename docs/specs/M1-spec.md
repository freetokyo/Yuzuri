# ユズリ M1 仕様 v1.0 — 入力フロー・SwiftData永続化

> 前提：M0（テンプレ解決・カテゴリ一覧描画）完了。本書はCLAUDE.md マイルストーン **M1** を具体化する。
> ゴール＝「解決済みテンプレを元にカテゴリ／項目を入力・保存でき、再起動後も保持。記入率が更新される」。

## 1. M1 の完成条件（受け入れ基準）

1. ホーム：全体の**記入率**（％）＋カテゴリ一覧（各カテゴリの記入状況バッジ）を表示。
2. カテゴリ画面：項目一覧（型に応じた入力UI）＋フリーテキスト欄。
3. 入力値が**SwiftDataに永続化**され、アプリ再起動後も保持される。
4. 値の編集で記入率・バッジが即時更新される。
5. カテゴリに「完了」トグルを持てる（任意。記入率とは独立）。
6. 秘匿フィールド（`type:"sensitive"`）は表示するが、**暗号化保存はM2に委譲**（M1ではプレースホルダ表示・非永続）。
7. ネットワークコード非存在を維持（CI継続）。

## 2. データモデル（SwiftData、CLAUDE.md §3と整合）

```swift
@Model final class NoteEntry {
    @Attribute(.unique) var categoryKey: String     // カテゴリ1件＝1レコード
    var structuredValues: [String:String]           // fieldKey: value（非秘匿のみ）
    var freeText: String
    var userMarkedDone: Bool                         // ユーザーが「完了」を明示
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var sensitive: [SensitiveBlob] // M2で使用
    init(categoryKey: String) { self.categoryKey = categoryKey
        structuredValues = [:]; freeText = ""; userMarkedDone = false; updatedAt = .now; sensitive = [] }
}
```

- 値は `fieldKey` をキーに保存（テンプレ非依存・言語非依存）。
- 秘匿値は `structuredValues` に**入れない**（M2で `SensitiveBlob` に暗号化）。

## 3. 記入率の定義（確定）

- 母数＝解決済みテンプレの**非秘匿フィールド総数**（秘匿は任意性が高いため母数から除外）。
- 分子＝値が非空の非秘匿フィールド数。
- 全体記入率＝分子／母数（％、四捨五入）。カテゴリ別記入率も同様。
- カテゴリバッジ：未記入（0%）／記入中（1–99%）／完了（100% もしくは `userMarkedDone`）。

## 4. 画面・フロー

**4.1 ホーム**
- 上部：全体記入率（リング or バー）。
- カテゴリ一覧（`order` 順）：カテゴリ名／記入率／バッジ。タップで4.2へ。
- 「次に書くとよい項目」提案（未記入カテゴリの先頭を数件、任意）。

**4.2 カテゴリ画面**
- 項目リスト（型別UI、4.3）。先頭〜末尾はテンプレ定義順。
- 末尾にフリーテキスト欄。
- カテゴリ `disclaimerKey` があれば注記表示（免責文ドラフト参照）。
- 「完了」トグル。

**4.3 項目入力UI（type別）**
| type | UI |
|---|---|
| text | TextField（1行） |
| multiline | TextEditor（複数行） |
| date | DatePicker |
| choice | Picker（選択肢はString Catalog or テンプレ拡張、M1は自由入力＋将来選択肢化でも可） |
| sensitive | 鍵アイコン＋「暗号化保存は次バージョンで対応」プレースホルダ（M1は非永続） |

## 5. 保存・更新

- **自動保存**：フィールドのfocus離脱／画面離脱でコミット。`updatedAt` 更新。
- カテゴリ初回編集時に `NoteEntry` を生成（lazy）。
- 破壊的操作なし（M1）。全削除等はM2以降で確認導線付き。

## 6. アーキテクチャ

- `TemplateStore`（M0の解決済みテンプレを保持・公開）。
- `EntryStore`（SwiftData `ModelContext` ラッパ。`entry(for:)`／`upsert`／記入率計算）。
- ビューは薄く、計算は `YuzuriKit` に寄せる。

```swift
struct ProgressCalculator {
    static func rate(categories: [CategoryDef], entries: [String:NoteEntry]) -> Double {
        let fields = categories.flatMap { $0.fields }.filter { $0.type != "sensitive" }
        guard !fields.isEmpty else { return 0 }
        let filled = fields.filter { f in
            entries.values.contains { $0.structuredValues[f.fieldKey]?.isEmpty == false }
        }.count
        return Double(filled) / Double(fields.count)
    }
}
```

## 7. テスト（XCTest）

- `testPersistAndReload`：値を保存→`ModelContext`再生成→値が残る。
- `testProgressExcludesSensitive`：秘匿項目は母数に含まれない。
- `testProgressUpdatesOnEdit`：1項目入力で記入率が上がる。
- `testCategoryBadgeStates`：0%／部分／完了の判定。
- `testLazyEntryCreation`：未編集カテゴリにレコードが作られない。

## 8. スコープ外（後続）

ロック・秘匿暗号化（M2）、PDF（M3）、アーカイブ（M4）、カスタム項目（M5）、多言語en切替の最終確認（M6）、課金（M7）。
