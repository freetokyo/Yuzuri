import Foundation

public enum EntryStatus: String, Codable, Sendable {
    case empty, inProgress, done
}

public struct ProgressCalculator: Sendable {

    public init() {}

    /// 全体記入率 (0.0 〜 1.0)。秘匿フィールドは母数に含まない。
    public func overallRate(categories: [CategoryDef], entries: [String: EntrySnapshot]) -> Double {
        let nonSensitiveFields = categories.flatMap { $0.fields }.filter { $0.type != "sensitive" }
        guard !nonSensitiveFields.isEmpty else { return 0 }
        let filled = nonSensitiveFields.filter { f in
            entries.values.contains { !(($0.structuredValues[f.fieldKey] ?? "").isEmpty) }
        }.count
        return Double(filled) / Double(nonSensitiveFields.count)
    }

    /// カテゴリ別記入率 (0.0 〜 1.0)。
    public func categoryRate(category: CategoryDef, entry: EntrySnapshot?) -> Double {
        let fields = category.fields.filter { $0.type != "sensitive" }
        guard !fields.isEmpty, let entry else { return 0 }
        let filled = fields.filter { !(entry.structuredValues[$0.fieldKey] ?? "").isEmpty }.count
        return Double(filled) / Double(fields.count)
    }

    /// カテゴリバッジ状態。
    public func categoryStatus(category: CategoryDef, entry: EntrySnapshot?) -> EntryStatus {
        guard let entry else { return .empty }
        if entry.userMarkedDone { return .done }
        let rate = categoryRate(category: category, entry: entry)
        if rate == 0 { return .empty }
        if rate >= 1.0 { return .done }
        return .inProgress
    }
}

/// SwiftData モデルを参照しない軽量スナップショット（テスト容易化）。
public struct EntrySnapshot: Sendable {
    public var categoryKey: String
    public var structuredValues: [String: String]
    public var userMarkedDone: Bool

    public init(categoryKey: String, structuredValues: [String: String] = [:], userMarkedDone: Bool = false) {
        self.categoryKey = categoryKey
        self.structuredValues = structuredValues
        self.userMarkedDone = userMarkedDone
    }
}
