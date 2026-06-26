import Foundation

public enum LocaleResolver {

    public static let supported: [String] = ["ja", "en"]

    /// 端末言語またはオーバーライドから対応ロケールを解決。未対応は "en" にフォールバック。
    public static func resolve(override: String? = nil) -> String {
        if let o = override, supported.contains(o) { return o }
        let langCode = Locale.preferredLanguages
            .first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            ?? "en"
        return supported.contains(langCode) ? langCode : "en"
    }
}
