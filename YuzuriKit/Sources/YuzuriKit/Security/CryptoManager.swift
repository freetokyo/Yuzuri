import Foundation
import CryptoKit

/// AES-GCM 暗号化ユーティリティ（端末内のみ。ネットワーク不使用）。
public enum CryptoManager {

    /// 端末固有の対称鍵をキーチェーンから取得または生成。
    public static func getOrCreateKey() throws -> SymmetricKey {
        let tag = "com.chen.yuzuri.sensitiveKey"
        if let existing = try loadKey(tag: tag) { return existing }
        let key = SymmetricKey(size: .bits256)
        try saveKey(key, tag: tag)
        return key
    }

    /// 平文 Data を AES-GCM で暗号化し (ciphertext, nonce) を返す。
    public static func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> (ciphertext: Data, nonce: Data) {
        let nonce = AES.GCM.Nonce()
        let box = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        return (box.combined ?? Data(), Data(nonce))
    }

    /// 暗号化済み (ciphertext, nonce) を復号して平文 Data を返す。
    public static func decrypt(ciphertext: Data, nonce nonceData: Data, using key: SymmetricKey) throws -> Data {
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }

    // MARK: - Keychain

    private static func loadKey(tag: String) throws -> SymmetricKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecReturnData: true,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw CryptoError.keychainRead(status)
        }
        return SymmetricKey(data: data)
    }

    private static func saveKey(_ key: SymmetricKey, tag: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let attrs: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tag,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(attrs as CFDictionary, nil)
        guard status == errSecSuccess else { throw CryptoError.keychainWrite(status) }
    }
}

public enum CryptoError: Error {
    case keychainRead(OSStatus)
    case keychainWrite(OSStatus)
}
