//
//  DownloadFileViewConfig.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import SwiftUI

public struct DownloadFileViewConfig {
    public static let normal = DownloadFileViewConfig(circleConfig: .normal,
                                                      maxWidth: .infinity,
                                                      maxHeight: .infinity,
                                                      iconWidth: 52,
                                                      iconHeight: 52,
                                                      iconColor: .iconColor.opacity(0.8),
                                                      circleProgressMaxWidth: 128
    )

    public static let small = DownloadFileViewConfig(circleConfig: .small,
                                                     maxWidth: .infinity,
                                                     maxHeight: .infinity,
                                                     iconWidth: 48,
                                                     iconHeight: 48,
                                                     iconColor: .iconColor.opacity(0.8),
                                                     circleProgressMaxWidth: 64
    )
    public var circleConfig: CircleProgressConfig
    public var maxWidth: CGFloat
    public var maxHeight: CGFloat
    public var iconWidth: CGFloat
    public var iconHeight: CGFloat
    public var iconColor: Color
    public var circleProgressMaxWidth: CGFloat

    public init(circleConfig: CircleProgressConfig,
                maxWidth: CGFloat,
                maxHeight: CGFloat,
                iconWidth: CGFloat,
                iconHeight: CGFloat,
                iconColor: Color,
                circleProgressMaxWidth: CGFloat
    ) {
        self.circleConfig = circleConfig
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.iconWidth = iconWidth
        self.iconHeight = iconHeight
        self.iconColor = iconColor
        self.circleProgressMaxWidth = circleProgressMaxWidth
    }
}
