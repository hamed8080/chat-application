//
//  NSMutableAttributedString+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
    func addLinkColor(_ text: String, _ color: UIColor = .blue) {
        let urlRegEx = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"
        if let linkRegex = try? NSRegularExpression(pattern: urlRegEx) {
            let allRange = NSRange(text.startIndex..., in: text)
            linkRegex.enumerateMatches(in: text, range: allRange) { (result, flag, _) in
                if let range = result?.range {
                    addAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
                }
            }
        }
    }
}
