import SwiftUI
import YuzuriKit

/// 解決済みテンプレートカテゴリを保持する Observable ストア。
@Observable
final class TemplateStore {
    private(set) var categories: [CategoryDef] = []
    private(set) var locale: String = LocaleResolver.resolve()

    func load(localeOverride: String? = nil) {
        let resolved = LocaleResolver.resolve(override: localeOverride)
        locale = resolved
        do {
            categories = try TemplateLoader.resolved(for: resolved, bundle: .main)
        } catch {
            categories = []
        }
    }
}
