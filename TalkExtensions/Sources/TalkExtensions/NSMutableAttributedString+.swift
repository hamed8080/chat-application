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
                if let range = result?.range, let urlRange = Range(range, in: string) {
                    let urlString = string[urlRange]
                    let sanitizedURL = String(urlString).trimmingCharacters(in: .whitespacesAndNewlines)
                    let encodedValue = sanitizedURL.data(using: .utf8)?.base64EncodedString()
                    let link = NSURL(string: "openURL:url?encodedValue=\(encodedValue ?? "")")
                    var attributedList: [NSAttributedString.Key : Any] = [
                        NSAttributedString.Key.foregroundColor: color,
                        NSAttributedString.Key.underlineColor: color,
                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                    ]
                    if let link = link {
                        attributedList[NSAttributedString.Key.link] = link
                    }
                    addAttributes(attributedList, range: range)
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
                    if let link = NSURL(string: "showUser:User?userName=\(sanitizedUserName)") {
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
