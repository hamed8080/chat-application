//
//  DownloadFileViewConfig.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import SwiftUI
import ChatDTO

public struct DownloadFileViewConfig {
    public static let normal = DownloadFileViewConfig(circleConfig: .normal,
                                                      maxWidth: .infinity,
                                                      maxHeight: .infinity,
                                                      iconWidth: 42,
                                                      iconHeight: 42,
                                                      iconColor: Color.App.primary,
                                                      circleProgressMaxWidth: 32,
                                                      fileNameTrailingSpace: 8,
                                                      showFileName: true,
                                                      showSkeleton: false
    )

    public static let small = DownloadFileViewConfig(circleConfig: .small,
                                                     maxWidth: .infinity,
                                                     maxHeight: .infinity,
                                                     iconWidth: 36,
                                                     iconHeight: 36,
                                                     iconColor: Color.App.bgPrimary,
                                                     circleProgressMaxWidth: 28,
                                                     fileNameTrailingSpace: 8,
                                                     showSkeleton: false
    )

    public static var detail: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = Color.App.green
        config.iconColor = Color.App.white
        config.iconCircleColor = Color.App.primary
        config.progressColor = Color.App.white
        config.showSkeleton = false
        return config
    }()

    public var circleConfig: CircleProgressConfig
    public var maxWidth: CGFloat
    public var maxHeight: CGFloat
    public var iconWidth: CGFloat
    public var iconHeight: CGFloat
    public var iconColor: Color
    public var iconCircleColor: Color
    public var progressColor: Color
    public var circleProgressMaxWidth: CGFloat
    public var showTrailingFileName: Bool
    public var showFileSize: Bool
    public var blurQuality: Float = 0.4
    public var blurSize: ImageSize = .SMALL
    public var fileNameTrailingSpace: CGFloat = 8
    public var showFileName: Bool = false
    /// If this property set to true it will not show the progress bar and only shows skeleton view.
    public var showSkeleton: Bool

    public init(circleConfig: CircleProgressConfig,
                maxWidth: CGFloat,
                maxHeight: CGFloat,
                iconWidth: CGFloat,
                iconHeight: CGFloat,
                iconColor: Color,
                iconCircleColor: Color = Color.App.white,
                progressColor: Color = Color.App.primary,
                circleProgressMaxWidth: CGFloat,
                showTrailingFileName: Bool = true,
                showFileSize: Bool = false,
                blurQuality: Float = 0.4,
                blurSize: ImageSize = .SMALL,
                fileNameTrailingSpace: CGFloat = 8,
                showFileName: Bool = false,
                showSkeleton: Bool
    ) {
        self.circleConfig = circleConfig
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.iconWidth = iconWidth
        self.iconHeight = iconHeight
        self.iconColor = iconColor
        self.iconCircleColor = iconCircleColor
        self.progressColor = progressColor
        self.circleProgressMaxWidth = circleProgressMaxWidth
        self.showTrailingFileName = showTrailingFileName
        self.showFileSize = showFileSize
        self.blurQuality = blurQuality
        self.blurSize = blurSize
        self.fileNameTrailingSpace = fileNameTrailingSpace
        self.showFileName = showFileName
        self.showSkeleton = showSkeleton
    }
}
