//
//  DateEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/6/21.
//

import Foundation
extension Date {
    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        date1.compare(self) == compare(date2)
    }

    var timeAgoSinceDate: String? {
        let now = Date.now
        return (self ..< now).formatted(.components(style: .narrow, fields: [.day, .month, .day, .hour, .minute])).string
    }

    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }

    func getDurationTimerString() -> String {
        let interval = Date().timeIntervalSince1970 - timeIntervalSince1970
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        return formatter.string(from: interval) ?? ""
    }

    func getDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd"
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
}
