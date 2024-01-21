//
//  NSMutableAttributedString+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {    
    func addLinkColor(_ color: UIColor = .blue) {
        if let linkRegex = NSRegularExpression.urlRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            linkRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range {
                    addAttributes([
                        NSAttributedString.Key.foregroundColor: color,
                        NSAttributedString.Key.underlineColor: color,
                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                    ], range: range)
                }
            }
        }
    }

    func addUserColor(_ color: UIColor = .blue) {
        if let userRegex = NSRegularExpression.userRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            userRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range, let userNameRange = Range(range, in: string) {
                    let userName = string[userNameRange]
                    let sanitizedUserName = String(userName).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
                    if let link = NSURL(string: "ShowUser:User?userName=\(sanitizedUserName)") {
                        addAttributes([
                            NSAttributedString.Key.link: link,
                            NSAttributedString.Key.foregroundColor: color
                        ], range: range)
                    }
                }
            }
        }
    }
}
