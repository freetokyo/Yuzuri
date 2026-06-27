import Foundation
import CryptoKit

// MARK: - アーカイブ形式（JSON → AES-GCM → .yuzuri）

public struct ArchivePayload: Codable, Sendable {
    public var version: Int
    public var exportedAt: Date
    public var categories: [CategoryArchive]

    public init(version: Int = 1, exportedAt: Date = .now, categories: [CategoryArchive]) {
        self.version = version
        self.exportedAt = exportedAt
        self.categories = categories
    }
}

public struct CategoryArchive: Codable, Sendable {
    public var categoryKey: String
    public var structuredValues: [String: String]
    public var freeText: String
    public var userMarkedDone: Bool
    public var updatedAt: Date
    public var sensitiveEntries: [SensitiveEntry]

    public init(categoryKey: String, structuredValues: [String: String],
                freeText: String, userMarkedDone: Bool, updatedAt: Date,
                sensitiveEntries: [SensitiveEntry] = []) {
        self.categoryKey = categoryKey
        self.structuredValues = structuredValues
        self.freeText = freeText
        self.userMarkedDone = userMarkedDone
        self.updatedAt = updatedAt
        self.sensitiveEntries = sensitiveEntries
    }
}

public struct SensitiveEntry: Codable, Sendable {
    public var fieldKey: String
    public var ciphertext: Data
    public var nonce: Data

    public init(fieldKey: String, ciphertext: Data, nonce: Data) {
        self.fieldKey = fieldKey
        self.ciphertext = ciphertext
        self.nonce = nonce
    }
}

// MARK: - ArchiveManager

public enum ArchiveManager {

    public static let fileExtension = "yuzuri"

    /// ペイロードをパスフレーズで暗号化してアーカイブ Data を返す。
    public static func export(payload: ArchivePayload, passphrase: String) throws -> Data {
        let jsonData = try JSONEncoder().encode(payload)
        let key = try deriveKey(from: passphrase)
        let (cipher, nonce) = try CryptoManager.encrypt(jsonData, using: key)
        // header: magic(4) + nonceLen(1) + nonce + ciphertext
        var result = Data()
        result.append(magic)
        var nonceLen = UInt8(nonce.count)
        result.append(Data(bytes: &nonceLen, count: 1))
        result.append(nonce)
        result.append(cipher)
        return result
    }

    /// アーカイブ Data をパスフレーズで復号してペイロードを返す。
    public static func `import`(data: Data, passphrase: String) throws -> ArchivePayload {
        guard data.count >= 5, data.prefix(4) == magic else { throw ArchiveError.invalidFormat }
        let nonceLen = Int(data[4])
        let nonceStart = 5
        let nonceEnd = nonceStart + nonceLen
        guard nonceEnd < data.count else { throw ArchiveError.invalidFormat }
        let nonce = data[nonceStart..<nonceEnd]
        let cipher = data[nonceEnd...]
        let key = try deriveKey(from: passphrase)
        let jsonData = try CryptoManager.decrypt(ciphertext: Data(cipher), nonce: Data(nonce), using: key)
        return try JSONDecoder().decode(ArchivePayload.self, from: jsonData)
    }

    // MARK: - Helpers

    private static let magic = Data([0x59, 0x5A, 0x52, 0x01]) // YZR\x01

    private static func deriveKey(from passphrase: String) throws -> SymmetricKey {
        // HKDF でパスフレーズから鍵導出（salt = magic）
        let inputKey = SymmetricKey(data: Data(passphrase.utf8))
        return HKDF<SHA256>.deriveKey(inputKeyMaterial: inputKey,
                                      salt: magic,
                                      info: Data("yuzuri.archive.v1".utf8),
                                      outputByteCount: 32)
    }
}

public enum ArchiveError: Error {
    case invalidFormat
    case wrongPassphrase
}
