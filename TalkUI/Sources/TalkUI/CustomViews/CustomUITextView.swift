//
//  CustomUITextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

public struct CustomUITextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let isEditable: Bool
    let iseUserInteractionEnabled: Bool
    let isSelectable: Bool
    let isScrollingEnabled: Bool
    let font: UIFont
    let textColor: UIColor?
    let size: CGSize

    public init(attributedText: NSAttributedString,
         size: CGSize = .init(width: 72, height: 48),
         isEditable: Bool = false,
         isScrollingEnabled: Bool = false,
         isSelectable: Bool = false,
         iseUserInteractionEnabled: Bool = true,
         font: UIFont = UIFont(name: "IRANSansX", size: 14) ?? UIFont.systemFont(ofSize: 14),
         textColor: UIColor? = UIColor(named: "text")) {
        self.attributedText = attributedText
        self.isEditable = isEditable
        self.iseUserInteractionEnabled = iseUserInteractionEnabled
        self.isScrollingEnabled = isScrollingEnabled
        self.isSelectable = isSelectable
        self.font = font
        self.textColor = textColor
        self.size = size
    }

    public func makeUIView(context: Context) -> some UIView {
        let textView = UITextView()
        textView.attributedText = attributedText
        textView.isEditable = isEditable
        textView.isUserInteractionEnabled = iseUserInteractionEnabled
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.isScrollEnabled = isScrollingEnabled
        textView.isSelectable = isSelectable
        textView.frame.origin.y = 0
        //        textView.translatesAutoresizingMaskIntoConstraints = false
        //        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        //        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return textView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
