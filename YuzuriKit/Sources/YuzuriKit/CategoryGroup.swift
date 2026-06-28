import Foundation

/// カテゴリをテーマ別にグループ化する。
/// 競合分析より：20項目の羅列は圧倒的に見えてユーザーが離脱しやすいため、
/// 意味的にまとめることで「どこから始めればいいか」を明示する。
public struct CategoryGroup: Identifiable, Sendable {
    public let id: String
    public let labelKey: String
    public let defaultLabel: String
    public let iconName: String
    public let categoryKeys: [String]

    public init(id: String, labelKey: String, defaultLabel: String,
                iconName: String, categoryKeys: [String]) {
        self.id = id
        self.labelKey = labelKey
        self.defaultLabel = defaultLabel
        self.iconName = iconName
        self.categoryKeys = categoryKeys
    }
}

public enum CategoryGrouping {
    /// 優先度順のグループ定義（研究より：まずは基本情報・資産から）
    public static let groups: [CategoryGroup] = [
        CategoryGroup(
            id: "personal",
            labelKey: "group.personal",
            defaultLabel: "About You",
            iconName: "person.fill",
            categoryKeys: ["profile", "lifeStory", "emergencyCard"]
        ),
        CategoryGroup(
            id: "assets",
            labelKey: "group.assets",
            defaultLabel: "Assets & Finance",
            iconName: "building.columns.fill",
            categoryKeys: [
                "assets.bank", "assets.securities", "assets.insurance",
                "assets.realEstate", "assets.pension", "assets.liabilities",
                "assets.cards", "assets.other", "recurringPayments"
            ]
        ),
        CategoryGroup(
            id: "wishes",
            labelKey: "group.wishes",
            defaultLabel: "Medical & Funeral Wishes",
            iconName: "heart.fill",
            categoryKeys: ["medical", "funeral", "estatePlanning", "pets", "digitalLegacy"]
        ),
        CategoryGroup(
            id: "messages",
            labelKey: "group.messages",
            defaultLabel: "Messages & Documents",
            iconName: "envelope.fill",
            categoryKeys: ["contacts", "messages", "documentLocations"]
        ),
    ]

    /// カテゴリキー → グループを逆引き
    public static func group(for categoryKey: String) -> CategoryGroup? {
        groups.first { $0.categoryKeys.contains(categoryKey) }
    }

    /// カテゴリグループごとに CategoryDef を振り分け
    public static func grouped(categories: [CategoryDef]) -> [(CategoryGroup, [CategoryDef])] {
        groups.compactMap { group in
            let cats = group.categoryKeys.compactMap { key in
                categories.first { $0.categoryKey == key }
            }
            return cats.isEmpty ? nil : (group, cats)
        }
    }

    /// 「次に書くべき」カテゴリ（未着手 or 記入中の先頭3件）
    public static func suggested(
        categories: [CategoryDef],
        entries: [String: EntrySnapshot],
        calc: ProgressCalculator,
        limit: Int = 3
    ) -> [CategoryDef] {
        categories
            .filter { calc.categoryStatus(category: $0, entry: entries[$0.categoryKey]) != .done }
            .prefix(limit)
            .map { $0 }
    }
}
