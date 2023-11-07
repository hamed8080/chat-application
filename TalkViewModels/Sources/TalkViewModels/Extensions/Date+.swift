//
//  Date+.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Additive
import Foundation

public extension Date {
    var localFormattedTime: String? {
        timeAgoSinceDateCondense(local: AppState.shared.preferredLocale)
    }

    var yearCondence: String? {
        yearCondence(local: AppState.shared.preferredLocale)
    }
}

public extension Int {
    var localFormattedTime : String? {
        let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(self)
        return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDateCondense(local: AppState.shared.preferredLocale)
    }
}
