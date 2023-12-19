//
//  Date+.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Additive
import Foundation
import TalkModels

public extension Date {
    var localFormattedTime: String? {
        timeAgoSinceDateCondense(local: Language.preferredLocale)
    }

    var yearCondence: String? {
        yearCondence(local: Language.preferredLocale)
    }

    var localTimeOrDate: String? {
        timeOrDate(local: Language.preferredLocale)
    }
}

public extension Int {
    var localFormattedTime : String? {
        let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(self)
        return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDateCondense(local: Language.preferredLocale)
    }
}
