//
//  Font+.swift
//  TalkUI
//
//  Created by hamed on 3/15/23.
//

import SwiftUI

public extension UIFont {
    static func register() {
        registerFont(name: "IRANSansX-Bold")
        registerFont(name: "IRANSansX-Regular")
    }

    private static func registerFont(name: String) {
        guard let fontURL = Bundle.module.url(forResource: name, withExtension: "ttf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}

public extension Font {
    static let iransansLargeTitle = Font.custom("IRANSansX", size: 24)
    static let iransansTitle = Font.custom("IRANSansX", size: 20)
    static let iransansSubtitle = Font.custom("IRANSansX", size: 18)
    static let iransansSubheadline = Font.custom("IRANSansX", size: 16)
    static let iransansBody = Font.custom("IRANSansX", size: 14)
    static let iransansCaption = Font.custom("IRANSansX", size: 13)
    static let iransansCaption2 = Font.custom("IRANSansX", size: 12)
    static let iransansCaption3 = Font.custom("IRANSansX", size: 11)
    static let iransansFootnote = Font.custom("IRANSansX", size: 10)

    static let iransansBoldLargeTitle = Font.custom("IRANSansX-Bold", size: 24)
    static let iransansBoldTitle = Font.custom("IRANSansX-Bold", size: 20)
    static let iransansBoldSubtitle = Font.custom("IRANSansX-Bold", size: 18)
    static let iransansBoldSubheadline = Font.custom("IRANSansX-Bold", size: 16)
    static let iransansBoldBody = Font.custom("IRANSansX-Bold", size: 14)
    static let iransansBoldCaption = Font.custom("IRANSansX-Bold", size: 13)
    static let iransansBoldCaption2 = Font.custom("IRANSansX-Bold", size: 12)
    static let iransansBoldCaption3 = Font.custom("IRANSansX-Bold", size: 11)
    static let iransansBoldFootnote = Font.custom("IRANSansX-Bold", size: 10)
}

public extension UIFont {
    static let uiiransansLargeTitle = UIFont(name: "IRANSansX", size: 24)
    static let uiiransansTitle = UIFont(name: "IRANSansX", size: 20)
    static let uiiransansSubtitle = UIFont(name: "IRANSansX", size: 18)
    static let uiiransansSubheadline = UIFont(name: "IRANSansX", size: 16)
    static let uiiransansBody = UIFont(name: "IRANSansX", size: 14)
    static let uiiransansCaption = UIFont(name: "IRANSansX", size: 13)
    static let uiiransansCaption2 = UIFont(name: "IRANSansX", size: 12)
    static let uiiransansCaption3 = UIFont(name: "IRANSansX", size: 11)
    static let uiiransansFootnote = UIFont(name: "IRANSansX", size: 10)

    static let uiiransansBoldLargeTitle = UIFont(name: "IRANSansX-Bold", size: 24)
    static let uiiransansBoldTitle = UIFont(name: "IRANSansX-Bold", size: 20)
    static let uiiransansBoldSubtitle = UIFont(name: "IRANSansX-Bold", size: 18)
    static let uiiransansBoldSubheadline = UIFont(name: "IRANSansX-Bold", size: 16)
    static let uiiransansBoldBody = UIFont(name: "IRANSansX-Bold", size: 14)
    static let uiiransansBoldCaption = UIFont(name: "IRANSansX-Bold", size: 13)
    static let uiiransansBoldCaption2 = UIFont(name: "IRANSansX-Bold", size: 12)
    static let uiiransansBoldCaption3 = UIFont(name: "IRANSansX-Bold", size: 11)
    static let uiiransansBoldFootnote = UIFont(name: "IRANSansX-Bold", size: 10)
}
