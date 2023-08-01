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
                                                      circleProgressMaxWidth: 128,
                                                      showSkeleton: false
    )

    public static let small = DownloadFileViewConfig(circleConfig: .small,
                                                     maxWidth: .infinity,
                                                     maxHeight: .infinity,
                                                     iconWidth: 48,
                                                     iconHeight: 48,
                                                     iconColor: .iconColor.opacity(0.8),
                                                     circleProgressMaxWidth: 64,
                                                     showSkeleton: true
    )
    public var circleConfig: CircleProgressConfig
    public var maxWidth: CGFloat
    public var maxHeight: CGFloat
    public var iconWidth: CGFloat
    public var iconHeight: CGFloat
    public var iconColor: Color
    public var circleProgressMaxWidth: CGFloat
    /// If this property set to true it will not show the progress bar and only shows skeleton view.
    public var showSkeleton: Bool

    public init(circleConfig: CircleProgressConfig,
                maxWidth: CGFloat,
                maxHeight: CGFloat,
                iconWidth: CGFloat,
                iconHeight: CGFloat,
                iconColor: Color,
                circleProgressMaxWidth: CGFloat,
                showSkeleton: Bool
    ) {
        self.circleConfig = circleConfig
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.iconWidth = iconWidth
        self.iconHeight = iconHeight
        self.iconColor = iconColor
        self.circleProgressMaxWidth = circleProgressMaxWidth
        self.showSkeleton = showSkeleton
    }
}
