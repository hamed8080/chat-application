//
//  ImageLaoderView.swift
//  ChatApplication
//
//  Created by hamed on 1/18/23.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

struct ImageLaoderView: View {
    @StateObject var imageLoader = ImageLoader()
    let url: String?
    let userName: String?
    let size: ImageSize

    init(url: String? = nil, userName: String? = nil, size: ImageSize = .SMALL) {
        self.url = url
        self.userName = userName
        self.size = size
    }

    var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(userName?.first ?? " "))
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .resizable()
            }
        }
        .onAppear {
            imageLoader.fetch(url: url, userName: userName, size: size)
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
