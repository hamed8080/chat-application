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
        if let cachedPreferedLocale = cachedPreferedLocale {
            return cachedPreferedLocale
        } else {
            let localIdentifier = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] })?.identifier
            let preferedLocale =  Locale(identifier: localIdentifier ?? "en_US")
            cachedPreferedLocale = preferedLocale
            return preferedLocale
        }
    }

    public static var preferredLocaleLanguageCode: String {
        return Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] })?.language ?? "en"
    }

    public static var rtlLanguages: [Language] {
        languages.filter{ $0.identifier == "ar_SA" || $0.identifier == "fa_IR" }
    }

    public static var isRTL: Bool {
        if let cachedIsRTL = cachedIsRTL {
            return cachedIsRTL
        } else {
            let isRTL = rtlLanguages.contains(where: {$0.language == Locale.preferredLanguages[0] })
            cachedIsRTL = isRTL
            return isRTL
        }
    }

    public static var preferedBundle: Bundle {
        if let cachedbundel = cachedbundel {
            return cachedbundel
        }
        guard
            let path = Bundle.main.path(forResource: preferredLocaleLanguageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        cachedbundel = bundle
        return bundle
    }

    private static var cachedbundel: Bundle?
    private static var cachedIsRTL: Bool?
    private static var cachedPreferedLocale: Locale?
}
