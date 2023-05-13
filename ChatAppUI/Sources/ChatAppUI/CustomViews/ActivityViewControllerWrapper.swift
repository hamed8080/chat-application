//
//  ActivityViewControllerWrapper.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import LinkPresentation
import SwiftUI

public struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    var activityItems: [URL]
    var applicationActivities: [UIActivity]?

    public init(activityItems: [URL], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    public func makeUIViewController(context _: Context) -> some UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [LinkMetaDataManager(url: activityItems.first!)], applicationActivities: nil)
        return vc
    }

    public func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}

public final class LinkMetaDataManager: NSObject, UIActivityItemSource {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        ""
    }

    public func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        url
    }

    public func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let image = UIImage(named: "global_app_icon")
        let imageProvider = NSItemProvider(object: image!)
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.imageProvider = imageProvider
        metadata.title = url.lastPathComponent
        return metadata
    }
}
