//
//  IntEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/29/21.
//

import Foundation
extension Int {
    static let unit: [String] = { ["KB", "MB", "GB", "TB", "PB", "EB"] }()
    var toSizeString: String {
        if self < 1000 { return "\(self) B" }
        let exp = Int(log2(Double(self)) / log2(1024.0))
        let unit = Int.unit[exp - 1]
        let number = Double(self) / pow(1024, Double(exp))
        return "\(number.formatted(.number.precision(.fractionLength(1)))) \(unit)"
    }
}
