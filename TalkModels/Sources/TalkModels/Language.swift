import Foundation

public struct Language: Identifiable {
    public var id: String { identifier }
    public let identifier: String
    public let language: String
    public let text: String

    public init(identifier: String, language: String, text: String) {
        self.identifier = identifier
        self.language = language
        self.text = text
    }

    public static let languages: [Language] = [
        .init(identifier: "en_US", language: "en-US", text: "English"),
        .init(identifier: "fa_IR", language: "fa-IR", text: "Persian (فارسی)"),
        .init(identifier: "sv_SE", language: "sv-SE", text: "Swedish"),
        .init(identifier: "de_DE", language: "de-DE", text: "Germany"),
        .init(identifier: "es_ES", language: "es-ES", text: "Spanish"),
        .init(identifier: "ar_SA", language: "ar-SA", text: "Arabic")
    ]

    public static var preferredLocale: Locale {
        let localIdentifier = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] })?.identifier
        return Locale(identifier: localIdentifier ?? "en_US")
    }
}
