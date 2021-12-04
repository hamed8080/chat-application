//
//  IntEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/29/21.
//

import Foundation
extension Int{
    
    var toSizeString:String{
        if (self < 1000) { return "\(self) B" }
        let exp = Int(log2(Double(self)) / log2(1024.0))
        let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
        let number = Double(self) / pow(1024, Double(exp))
        return String(format: "%.1f %@", number, unit)
    }
}
