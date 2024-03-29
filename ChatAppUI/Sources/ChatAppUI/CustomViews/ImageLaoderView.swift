//
//  ImageLaoderView.swift
//  ChatApplication
//
//  Created by hamed on 1/18/23.
//

import Chat
import Foundation
import SwiftUI
import ChatAppModels
import ChatDTO

public struct ImageLaoderView: View {
    @StateObject var imageLoader = ImageLoader()
    @Environment(\.isPreview) var isPreview
    let url: String?
    let metaData: String?
    let userName: String?
    let size: ImageSize

    public init(url: String? = nil, metaData: String? = nil, userName: String? = nil, size: ImageSize = .SMALL) {
        self.metaData = metaData
        self.url = url
        self.userName = userName
        self.size = size
    }

    public var body: some View {
        if isPreview {
            Image(url ?? "")
                .resizable()
        } else {
            ZStack {
                if !imageLoader.isImageReady {
                    Text(String(userName?.first ?? " "))
                } else if imageLoader.isImageReady {
                    Image(uiImage: imageLoader.image)
                        .resizable()
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
}

struct ImageLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        ImageLaoderView(url: "https://podspace.podland.ir/api/images/FQW4R5QUPE4XNDUV", userName: "Hamed")
            .font(.system(size: 16).weight(.heavy))
            .foregroundColor(.white)
            .frame(width: 128, height: 128)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(64)
            .overlay {
                RoundedRectangle(cornerRadius: 64)
                    .stroke(.mint, lineWidth: 2)
            }
    }
}
