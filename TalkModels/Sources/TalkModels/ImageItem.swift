import Foundation
public struct ImageItem: Hashable, Identifiable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    public let id = UUID().uuidString
    public var imageData: Data
    public var phAsset: NSObject
    public var info: [AnyHashable: Any]?
    public var originalFilename: String?
    public var fileName: String? { originalFilename }
    public var width: Int
    public var height: Int

    public init(imageData: Data,
                width: Int,
                height: Int,
                phAsset: NSObject,
                info: [AnyHashable : Any]? = nil,
                originalFilename: String? = nil) {
        self.width = width
        self.height = height
        self.imageData = imageData
        self.phAsset = phAsset
        self.info = info
        self.originalFilename = originalFilename
    }
}
