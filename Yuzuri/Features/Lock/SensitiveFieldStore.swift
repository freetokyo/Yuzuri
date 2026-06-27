import SwiftUI
import SwiftData
import YuzuriKit

/// 秘匿フィールドの暗号化保存と復号表示を管理する。
@Observable
@MainActor
final class SensitiveFieldStore {

    // 復号済み値のキャッシュ (fieldKey: value)
    private(set) var decrypted: [String: String] = [:]
    var isUnlocked = false

    // MARK: - Unlock

    func unlockSensitive() async -> Bool {
        let ok = await LockManager.shared.authenticate(reason: "秘匿情報を表示します")
        if ok { isUnlocked = true }
        return ok
    }

    func lockSensitive() {
        isUnlocked = false
        decrypted = [:]
    }

    // MARK: - Save

    func save(value: String, fieldKey: String, entry: NoteEntry, ctx: ModelContext) {
        guard !value.isEmpty else {
            // 空 → 既存 blob を明示削除（removeAll だけでは SwiftData が孤立ブロブを残す）
            let toDelete = entry.sensitive.filter { $0.fieldKey == fieldKey }
            toDelete.forEach { ctx.delete($0) }
            entry.sensitive.removeAll { $0.fieldKey == fieldKey }
            try? ctx.save()
            return
        }
        do {
            let key = try CryptoManager.getOrCreateKey()
            let plain = Data(value.utf8)
            let (cipher, nonce) = try CryptoManager.encrypt(plain, using: key)
            if let blob = entry.sensitive.first(where: { $0.fieldKey == fieldKey }) {
                blob.ciphertext = cipher
                blob.nonce = nonce
            } else {
                let blob = SensitiveBlob(fieldKey: fieldKey, ciphertext: cipher, nonce: nonce)
                entry.sensitive.append(blob)
                ctx.insert(blob)
            }
            entry.updatedAt = .now
            try? ctx.save()
        } catch {
            // 暗号化失敗は静かに失敗（機微情報を平文で保存しない）
        }
    }

    // MARK: - Decrypt all for entry

    func decryptAll(entry: NoteEntry) {
        guard isUnlocked else { return }
        do {
            let key = try CryptoManager.getOrCreateKey()
            for blob in entry.sensitive {
                if let data = try? CryptoManager.decrypt(ciphertext: blob.ciphertext, nonce: blob.nonce, using: key),
                   let str = String(data: data, encoding: .utf8) {
                    decrypted[blob.fieldKey] = str
                }
            }
        } catch {}
    }
}
