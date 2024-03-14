//
//  PaddingUILabel.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import UIKit

public class PaddingUILabel: UILabel {
    private let horizontal: CGFloat
    private let vertical: CGFloat

    public init(frame: CGRect, horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
        super.init(frame: frame)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + horizontal, height: size.height + vertical)
    }
}
