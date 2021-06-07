//
//  DateEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/6/21.
//

import Foundation
extension Date {
    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }
    
    func timeAgoSinceDate() -> String {
        
        // From Time
        let fromDate = self
        
        // To Time
        let toDate = Date()
        
        // Estimation
        // Year
        if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {
            return "\(interval)" + " " + (interval == 1 ? "Year ago" : "Years ago")
        }
        
        // Month
        if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {
            return "\(interval)" + " " + (interval == 1 ? "Month ago" : "Months ago")
        }
        
        // Day
        if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {
            return "\(interval)" + " " + (interval == 1 ? "Day ago" : "Days ago")
        }
        
        // Hours
        if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {
            return "\(interval)" + " " + (interval == 1 ? "Hour ago" : "Hours ago")
        }
        
        // Minute
        if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {
            return  "\(interval)" + " " + (interval == 1 ? "Minute ago" : "Minutes ago")
        }
        
        return "last seen recently"
    }
    
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
    
}
