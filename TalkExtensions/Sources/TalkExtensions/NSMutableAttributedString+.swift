//
//  NSMutableAttributedString+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
    static let urlRegEx = try? NSRegularExpression(pattern: "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)")
    static let userRegEx = try? NSRegularExpression(pattern: "@[0-9a-zA-Z\\-\\p{Arabic}](\\.?[0-9a-zA-Z\\--\\p{Arabic}])*")
    
    func addLinkColor(_ color: UIColor = .blue) {
        if let linkRegex = NSMutableAttributedString.urlRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            linkRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range {
                    addAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
                }
            }
        }
    }

    func addUserColor(_ color: UIColor = .blue) {
        if let userRegex = NSMutableAttributedString.userRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            userRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range, let userNameRange = Range(range, in: string) {
                    let userName = string[userNameRange]
                    let sanitizedUserName = String(userName).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
                    if let link = NSURL(string: "ShowUser:User?userName=\(sanitizedUserName)") {
                        addAttributes([NSAttributedString.Key.link: link], range: range)
                        addAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
                    }
                }
            }
        }
    }
}
