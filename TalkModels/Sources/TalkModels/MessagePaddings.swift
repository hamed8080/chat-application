//
//  File.swift
//  
//
//  Created by hamed on 2/5/24.
//

import Foundation
import SwiftUI

public struct MessagePaddings {
    public var textViewPadding: EdgeInsets
    public var textViewSpacingTop: CGFloat = 0
    public var replyViewSpacingTop: CGFloat = 0
    public var forwardViewSpacingTop: CGFloat = 0
    public var fileViewSpacingTop: CGFloat = 0
    public var paddingEdgeInset: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    public var radioPadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 0)
    public var mapViewSapcingTop: CGFloat = 0
    public var groupParticipantNamePadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 0)
    
    public init(
        textViewPadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    ) {
        self.textViewPadding = textViewPadding
    }
}
