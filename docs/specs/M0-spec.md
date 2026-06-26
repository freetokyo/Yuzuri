# ユズリ M0 スパイク仕様 v1.0 — 雛形・テンプレローダ・ロケール解決

> 目的：CLAUDE.md のマイルストーン **M0** をClaude Codeが着手できる粒度に具体化する。
> ゴール＝「base＋ロケール差分をマージして、解決済みカテゴリ一覧を日本語/英語で描画できる」。通信コードは一切含めない。

## 1. M0 の完成条件（受け入れ基準）

1. Xcodeプロジェクト＋`YuzuriKit`（SPM）が作成され、ビルドが通る。
2. `Resources/Templates/` に `template.base.json` / `template.ja.json` / `template.en.json` を同梱。
3. `TemplateLoader` が base＋ロケール差分をマージし、**en=20カテゴリ/68項目、ja=20カテゴリ/72項目**を返す（テストで固定）。
4. JP差分が正しい位置に入る：profileに`本籍`（placeOfBirthの直後）、funeralに`宗派`/`香典`（religionの後）と`お墓の承継`（burialの後）。
5. `LocaleResolver` が端末言語/設定から `ja`/`en` を解決し、未対応言語は `en` にフォールバック。
6. ラベルは String Catalog（labelKey）で解決、未登録時は `defaultLabel` にフォールバック。
7. ホーム画面に、解決済みカテゴリを `order` 順で一覧表示。言語切替で表示が切り替わる。
8. **ネットワークコードが存在しない**（`URLSession`等の不使用をgrepで確認、CIに含める）。

## 2. テンプレのスキーマ

**base（`role:"base"`）**
```
{ templateVersion, role:"base", fieldTypes:[...],
  categories:[ { categoryKey, labelKey, defaultLabel, order, disclaimerKey,
                 fields:[ { fieldKey, labelKey, defaultLabel, type, defaultSensitive } ] } ] }
```

**overlay（`extends:"base"`）**
```
{ locale, templateVersion, extends:"base",
  removeCategories:[categoryKey], removeFields:[fieldKey],
  addCategories:[ {完全なcategory} ],
  addFields:[ { categoryKey, afterFieldKey?, field:{...} } ],
  overrides:{ "<categoryKey|fieldKey>": { order?, disclaimerKey?, defaultSensitive? } } }
```

## 3. マージアルゴリズム（確定仕様）

順序厳守：
1. base のカテゴリ配列を複製。
2. `removeCategories` → 該当カテゴリ削除。
3. `removeFields` → 全カテゴリから該当フィールド削除。
4. `addCategories` → 追加。
5. `addFields` → `categoryKey`へ追加。`afterFieldKey`があればその直後に挿入、無ければ末尾。
6. `overrides` → カテゴリ/フィールドの `order`/`disclaimerKey`/`defaultSensitive` を上書き。
7. カテゴリを `order` 昇順にソート（フィールドは定義順を維持）。

※この仕様は検証済み（en=68 / ja=72、JP差分の挿入位置確認済み）。

## 4. Swift 実装スケッチ（YuzuriKit/Localization）

```swift
// MARK: - Decodable models
struct FieldDef: Codable, Identifiable {
    let fieldKey: String
    let labelKey: String
    let defaultLabel: String
    let type: String              // text/multiline/date/choice/sensitive
    let defaultSensitive: Bool
    var id: String { fieldKey }
}
struct CategoryDef: Codable, Identifiable {
    let categoryKey: String
    let labelKey: String
    let defaultLabel: String
    var order: Int
    var disclaimerKey: String?
    var fields: [FieldDef]
    var id: String { categoryKey }
}
struct BaseTemplate: Codable { let role: String; let categories: [CategoryDef] }

struct AddFieldOp: Codable { let categoryKey: String; let afterFieldKey: String?; let field: FieldDef }
struct OverrideOp: Codable { let order: Int?; let disclaimerKey: String?; let defaultSensitive: Bool? }
struct Overlay: Codable {
    let locale: String
    let removeCategories: [String]?
    let removeFields: [String]?
    let addCategories: [CategoryDef]?
    let addFields: [AddFieldOp]?
    let overrides: [String: OverrideOp]?
}

// MARK: - Loader
enum TemplateLoader {
    static func resolved(for locale: String, bundle: Bundle = .main) throws -> [CategoryDef] {
        let base = try decode(BaseTemplate.self, "template.base", bundle).categories
        let overlay = (try? decode(Overlay.self, "template.\(locale)", bundle))
                   ?? (try decode(Overlay.self, "template.en", bundle))   // fallback
        return merge(base: base, overlay: overlay)
    }

    static func merge(base: [CategoryDef], overlay: Overlay) -> [CategoryDef] {
        var cats = base
        if let rc = overlay.removeCategories { cats.removeAll { rc.contains($0.categoryKey) } }
        if let rf = overlay.removeFields {
            for i in cats.indices { cats[i].fields.removeAll { rf.contains($0.fieldKey) } }
        }
        if let ac = overlay.addCategories { cats.append(contentsOf: ac) }
        if let af = overlay.addFields {
            for op in af {
                guard let ci = cats.firstIndex(where: { $0.categoryKey == op.categoryKey }) else { continue }
                if let after = op.afterFieldKey,
                   let fi = cats[ci].fields.firstIndex(where: { $0.fieldKey == after }) {
                    cats[ci].fields.insert(op.field, at: fi + 1)
                } else {
                    cats[ci].fields.append(op.field)
                }
            }
        }
        if let ov = overlay.overrides {
            for i in cats.indices {
                if let o = ov[cats[i].categoryKey] {
                    if let v = o.order { cats[i].order = v }
                    if let v = o.disclaimerKey { cats[i].disclaimerKey = v }
                }
                for j in cats[i].fields.indices {
                    if let o = ov[cats[i].fields[j].fieldKey], let v = o.defaultSensitive {
                        // FieldDef is immutable here; in production make fields var or rebuild
                        _ = v
                    }
                }
            }
        }
        return cats.sorted { $0.order < $1.order }
    }

    private static func decode<T: Decodable>(_ t: T.Type, _ name: String, _ bundle: Bundle) throws -> T {
        let url = bundle.url(forResource: name, withExtension: "json")!
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}

// MARK: - Locale resolution
enum LocaleResolver {
    static let supported = ["ja", "en"]
    static func resolve(override: String? = nil) -> String {
        if let o = override, supported.contains(o) { return o }
        let lang = Locale.preferredLanguages.first.map { Locale(identifier: $0).language.languageCode?.identifier ?? "en" } ?? "en"
        return supported.contains(lang) ? lang : "en"   // fallback en
    }
}

// MARK: - Label resolution (String Catalog with fallback)
func label(_ key: String, fallback: String) -> String {
    let s = NSLocalizedString(key, comment: "")
    return s == key ? fallback : s
}
```

> 実装メモ：`FieldDef.defaultSensitive` を `overrides` で変えるなら `FieldDef` を可変化するか、マージ時に再構築する。M0では `overrides` は未使用でも可（ja/enともに空）。

## 5. テスト（XCTest）

- `testEnResolvedCounts`：en → 20カテゴリ / 68項目。
- `testJaResolvedCounts`：ja → 20カテゴリ / 72項目。
- `testJaProfileHasRegisteredDomicileAfterPlaceOfBirth`：本籍がplaceOfBirthの直後。
- `testJaFuneralAdditions`：宗派/香典/お墓の承継が存在し位置が正しい。
- `testUnsupportedLocaleFallsBackToEn`：`fr` → enと同一結果。
- `testNoNetworkSymbols`（任意）：バイナリ/ソースに`URLSession`等が無いことを確認。

## 6. M0 で作らないもの

入力UI（M1）、ロック/暗号（M2）、PDF（M3）、アーカイブ（M4）、カスタム項目（M5）、課金（M7）。M0は「ロード→一覧描画」に限定。
