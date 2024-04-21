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

    var fileDateString: String {
        let date = Date()
        let calendar = Calendar.current
        let dateCmp = calendar.dateComponents([.year, .month, .day], from: date)
        let timeCmp = calendar.dateComponents([.hour, .minute], from: date)
        let dateString = "\(dateCmp.year ?? 0)-\(dateCmp.month ?? 0)-\(dateCmp.day ?? 0)"
        let time = "\(timeCmp.hour ?? 0)-\(timeCmp.minute ?? 0)"
        return "\(dateString)-\(time)"
    }

    var onlyLocaleTime: String {
        getTime(localIdentifire: Language.preferredLocale.identifier)
    }
}

public extension Int {
    var localFormattedTime : String? {
        let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(self)
        return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDateCondense(local: Language.preferredLocale)
    }
}
