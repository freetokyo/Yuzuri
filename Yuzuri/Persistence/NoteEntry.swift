import Foundation
import SwiftData
import YuzuriKit

/// カテゴリ1件の入力レコード。categoryKey を主キーとして1レコード。
///
/// ⚠️ ネスト Codable を直接 @Model に保存しない（SwiftData 教訓）。
/// [String:String] は SwiftData がサポートするプリミティブ辞書なので直接保存可。
@Model
final class NoteEntry {
    @Attribute(.unique) var categoryKey: String
    var structuredValues: [String: String]
    var freeText: String
    var userMarkedDone: Bool
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var sensitive: [SensitiveBlob]

    init(categoryKey: String) {
        self.categoryKey = categoryKey
        self.structuredValues = [:]
        self.freeText = ""
        self.userMarkedDone = false
        self.updatedAt = .now
        self.sensitive = []
    }

    /// YuzuriKit のスナップショットに変換（ビュー/計算用）。
    func snapshot() -> EntrySnapshot {
        EntrySnapshot(categoryKey: categoryKey,
                      structuredValues: structuredValues,
                      userMarkedDone: userMarkedDone)
    }
}

/// 秘匿データ（M2 で CryptoKit 暗号化を実装）。M1 では骨格のみ。
@Model
final class SensitiveBlob {
    var fieldKey: String
    var ciphertext: Data
    var nonce: Data

    init(fieldKey: String, ciphertext: Data = Data(), nonce: Data = Data()) {
        self.fieldKey = fieldKey
        self.ciphertext = ciphertext
        self.nonce = nonce
    }
}
