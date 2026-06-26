import Foundation
import LocalAuthentication

/// アプリロック状態の管理。SwiftUI 側は @Observable LockGateStore でラップ。
public actor LockManager {

    public static let shared = LockManager()
    private init() {}

    /// 生体認証でアンロックを試みる。成功で true。
    public func authenticate(reason: String) async -> Bool {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true // 認証デバイスなし → 通す
        }
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
