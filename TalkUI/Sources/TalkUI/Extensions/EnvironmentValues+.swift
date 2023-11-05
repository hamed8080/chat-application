import SwiftUI

public extension EnvironmentValues {
    var isPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif
    }

    static var isDebug: Bool {
#if DEBUG
        return true
#endif
        return false
    }

    static var isTalkTest: Bool {
        (Bundle.main.bundleIdentifier?.contains("talk-test") ?? false) && isDebug
    }
}
