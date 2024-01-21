//
//  NSRegularExpression+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation

public extension NSRegularExpression {
    static let urlRegEx = try? NSRegularExpression(pattern: "(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})")
    static let userRegEx = try? NSRegularExpression(pattern: "@[0-9a-zA-Z\\-\\p{Arabic}](\\.?[0-9a-zA-Z\\--\\p{Arabic}])*")

}
