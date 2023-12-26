//
//  ImageLoaderView.swift
//  TalkUI
//
//  Created by hamed on 1/18/23.
//

import Chat
import Foundation
import SwiftUI
import TalkModels
import TalkViewModels
import ChatDTO

public struct ImageLoaderView: View {
    @StateObject var imageLoader: ImageLoaderViewModel
    let contentMode: ContentMode
    let textFont: Font

    public init(imageLoader: ImageLoaderViewModel,
                contentMode: ContentMode = .fill,
                textFont: Font = .iransansBody
    ) {
        self.textFont = textFont
        self.contentMode = contentMode
        self._imageLoader = StateObject(wrappedValue: imageLoader)
    }

    public var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(imageLoader.config.userName?.first ?? " "))
                    .font(textFont)
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .animation(.easeInOut, value: imageLoader.image)
        .animation(.easeInOut, value: imageLoader.isImageReady)
        .onAppear {
            if !imageLoader.isImageReady {
                imageLoader.fetch()
            }
        }
    }
}

struct ImageLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ImageLoaderConfig(url: "https://podspace.podland.ir/api/images/FQW4R5QUPE4XNDUV", userName: "Hamed")
        ImageLoaderView(imageLoader: ImageLoaderViewModel(config: config))
            .font(.system(size: 16).weight(.heavy))
            .foregroundColor(.white)
            .frame(width: 128, height: 128)
            .background(Color.App.blue.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius:(64)))
            .overlay {
                RoundedRectangle(cornerRadius: 64)
                    .stroke(.mint, lineWidth: 2)
            }
    }
}
