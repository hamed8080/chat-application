//
//  EnvironmentEX.swift
//  ChatApplication
//
//  Created by hamed on 4/9/22.
//

import SwiftUI

public extension EnvironmentValues {
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}
