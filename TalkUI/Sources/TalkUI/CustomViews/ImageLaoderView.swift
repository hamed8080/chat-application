//
//  ImageLaoderView.swift
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

public struct ImageLaoderView: View {
    @StateObject var imageLoader: ImageLoaderViewModel
    let url: String?
    let metaData: String?
    let userName: String?
    let size: ImageSize

    public init(imageLoader: ImageLoaderViewModel, url: String? = nil, metaData: String? = nil, userName: String? = nil, size: ImageSize = .SMALL) {
        self.metaData = metaData
        self.url = url
        self.userName = userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.size = size
        self._imageLoader = StateObject(wrappedValue: imageLoader)
    }

    public var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(userName?.first ?? " "))
                    .font(.iransansBody)
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .animation(.easeInOut, value: imageLoader.image)
        .animation(.easeInOut, value: imageLoader.isImageReady)
        .onAppear {
            if !imageLoader.isImageReady {
                imageLoader.fetch(url: url, metaData: metaData, userName: userName, size: size)
            }
        }
    }
}

struct ImageLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: "https://podspace.podland.ir/api/images/FQW4R5QUPE4XNDUV", userName: "Hamed")
            .font(.system(size: 16).weight(.heavy))
            .foregroundColor(.white)
            .frame(width: 128, height: 128)
            .background(Color.App.blue.opacity(0.4))
            .cornerRadius(64)
            .overlay {
                RoundedRectangle(cornerRadius: 64)
                    .stroke(.mint, lineWidth: 2)
            }
    }
}
