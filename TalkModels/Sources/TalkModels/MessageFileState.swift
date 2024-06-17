import Foundation
import UIKit

public struct MessageFileState {
    public var progress: CGFloat
    public var showDownload: Bool
    public var isUploading: Bool
    public var isUploadCompleted: Bool
    public var state: DownloadFileState
    public var iconState: String
    public var blurRadius: CGFloat
    public var image: UIImage?

    public init(progress: CGFloat = 0.0,
                showImage: Bool = false,
                showDownload: Bool = false,
                isUploading: Bool = false,
                isUploadCompleted: Bool = false,
                state: DownloadFileState = .undefined,
                iconState: String = "arrow.down",
                blurRadius: CGFloat = 0,
                image: UIImage? = nil) {
        self.progress = progress
        self.showDownload = showDownload
        self.isUploading = isUploading
        self.isUploadCompleted = isUploadCompleted
        self.state = state
        self.iconState = iconState
        self.blurRadius = blurRadius
        self.image = image
    }

    mutating public func update(_ newState: MessageFileState) {
        let oldImage = image
        self = newState
        if newState.state == .downloading, let oldImage = oldImage {
            image = oldImage
        }
    }
}
