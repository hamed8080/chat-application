//
//  Avatar.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct Avatar: View {
    @ObservedObject
    var imageLoader: ImageLoader

    @Environment(\.isPreview)
    var isPreview

    private(set) var url: String?
    private(set) var userName: String?
    private(set) var style: StyleConfig = .init()
    private(set) var previewImageName: String = "avatar"
    private(set) var token: String?
    private(set) var metadata: String?
    private(set) var size: ImageSize = .SMALL

    struct StyleConfig {
        var cornerRadius: CGFloat = 2
        var size: CGFloat = 64
        var textSize: CGFloat = 24
    }

    init(imageLoader: ImageLoader? = nil, url: String?, userName: String? = nil, style: StyleConfig = .init(), size: ImageSize = .SMALL, metadata: String? = nil, token: String? = nil) {
        self.url = url
        self.imageLoader = imageLoader ?? ImageLoader(url: url ?? "")
        self.metadata = metadata
        self.token = token
        self.size = size
        self.style = style
        self.userName = userName
        if url != nil {
            self.imageLoader.fetch()
        }
    }

    var body: some View {
        if isPreview {
            previewView
        } else {
            HStack(alignment: .center) {
                if url != nil {
                    if imageLoader.isImageReady {
                        readyImageView
                    } else {
                        placeholderView
                    }
                } else {
                    userFirstNameView
                }
            }
            .animation(.easeInOut, value: imageLoader.image)
        }
    }

    @ViewBuilder
    var previewView: some View {
        Image(previewImageName)
            .resizable()
            .frame(width: style.size, height: style.size)
            .cornerRadius(style.size / style.cornerRadius)
            .scaledToFit()
    }

    @ViewBuilder
    var readyImageView: some View {
        Image(uiImage: imageLoader.image)
            .resizable()
            .frame(width: style.size, height: style.size)
            .cornerRadius(style.size / style.cornerRadius)
            .scaledToFit()
    }

    @ViewBuilder
    var placeholderView: some View {
        Image(systemName: "photo.circle.fill")
            .resizable()
            .foregroundColor(.gray.opacity(0.5))
            .frame(width: style.size, height: style.size)
            .cornerRadius(style.size / style.cornerRadius)
            .scaledToFit()
    }

    @ViewBuilder
    var userFirstNameView: some View {
        Text(String(userName?.first ?? "A"))
            .fontWeight(.heavy)
            .font(.system(size: style.textSize))
            .foregroundColor(.white)
            .frame(width: style.size, height: style.size)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(style.size / style.cornerRadius)
    }
}

struct Acatar_Previews: PreviewProvider {
    static var previews: some View {
        Avatar(url: nil)
    }
}
