//
//  ThreadImageView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadImageView: View {
    @State var thread: Conversation
    let threadsVM: ThreadsViewModel

    var body: some View {
        if thread.type == .selfThread {
            Circle()
                .foregroundColor(.clear)
                .scaledToFit()
                .frame(width: 48, height: 48)
                .background(.ultraThickMaterial)
                .cornerRadius(32)
                .overlay {
                    Image("bookmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
        } else if let image = thread.computedImageURL {
            ImageLaoderView(imageLoader: threadsVM.avatars(for: image), url: thread.computedImageURL, metaData: image, userName: thread.title)
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
        } else {
            Text(verbatim: String(thread.computedTitle.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " "))
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
        }
    }
}
