//
//  AppOverlayViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Combine
import ChatModels
import SwiftUI

public enum AppOverlayTypes {
    case gallery(message: Message)
    case galleryImageView(uiimage: UIImage)
    case none
}

public class AppOverlayViewModel: ObservableObject {
    @Published public var isPresented = false
    public var type: AppOverlayTypes = .none

    public var galleryMessage: Message? = nil {
        didSet {
            guard let galleryMessage else { return }
            type = .gallery(message: galleryMessage)
            isPresented = true
        }
    }

    public var galleryImageView: UIImage? {
        didSet {
            guard let galleryImageView else { return }
            type = .galleryImageView(uiimage: galleryImageView)
            isPresented = true
        }
    }

    public func clear() {
        galleryMessage = nil
        galleryImageView = nil
    }
}
