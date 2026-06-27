import SwiftUI
import YuzuriKit

@Observable
@MainActor
final class LockGateStore {
    var isLocked: Bool = {
        #if DEBUG
        if CommandLine.arguments.contains("-FORCE_UNLOCK") { return false }
        #endif
        return true
    }()
    var isAuthenticating = false

    func unlock() async {
        guard isLocked else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let ok = await LockManager.shared.authenticate(reason: "ユズリを開く")
        if ok { isLocked = false }
    }

    /// バックグラウンド復帰時に再ロック（タイムアウト設定は将来拡張）。
    func lockOnBackground() {
        isLocked = true
    }
}
