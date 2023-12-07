import Foundation
public class ImageItem: Hashable, Identifiable, ObservableObject {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    public var id: String
    public var imageData: Data
    public var phAsset: NSObject
    public var info: [AnyHashable: Any]?
    public var originalFilename: String?
    public var fileName: String? { originalFilename }
    public var width: Int
    public var height: Int
    public var isIniCloud: Bool
    public var icouldDownloadProgress: Double
    public var isSelected = false

    public init(id: String,
                imageData: Data,
                width: Int,
                height: Int,
                phAsset: NSObject,
                isIniCloud: Bool,
                icouldDownloadProgress: Double = 0.0,
                info: [AnyHashable : Any]? = nil,
                originalFilename: String? = nil) {
        self.id = id
        self.width = width
        self.height = height
        self.imageData = imageData
        self.phAsset = phAsset
        self.info = info
        self.originalFilename = originalFilename
        self.isIniCloud = isIniCloud
        self.icouldDownloadProgress = icouldDownloadProgress
    }

    @MainActor
    public func setDownloadProgress(_ progress: Double) async {
        self.icouldDownloadProgress = progress
        if progress == 1.0 {
            isIniCloud = false
        }
        objectWillChange.send()
    }
}
