//
//  AppOverlayFactory.swift
//  Talk
//
//  Created by hamed on 9/20/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct AppOverlayFactory: View {
    @EnvironmentObject var viewModel: AppOverlayViewModel

    var body: some View {
        switch viewModel.type {
        case .gallery(let message):
            GalleryView(message: message)
                .id(message.id)
        case .galleryImageView(let image):
            ZStack {
                GalleryImageView(uiimage: image)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .fullScreenBackgroundView()
            .ignoresSafeArea(.all)
        case .dialog:
            if let dialog = viewModel.dialogView {
                dialog
                    .background(.ultraThickMaterial)
                    .ignoresSafeArea(.all)
            }
        case .toast(let leadingView, let message, let messageColor):
            ToastView(message: message, messageColor: messageColor) {
                leadingView
            }
        case .error(let error):
            if let localizedError = error?.localizedError {
                ToastView(title: "", message: localizedError) {}
            } else {
                let title = String(format: String(localized: "Errors.occuredTitle"), "\(error?.code ?? 0)")
                ToastView(title: title, message: error?.message ?? "") {}
            }
        case .none:
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}

struct AppOverlayFactory_Previews: PreviewProvider {
    static var previews: some View {
        AppOverlayFactory()
    }
}

