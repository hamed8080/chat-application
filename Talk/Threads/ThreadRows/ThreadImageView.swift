//
//  ThreadImageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadImageView: View {
    @State var thread: Conversation
    let threadsVM: ThreadsViewModel
    @State private var computedImageURL: String?

    var body: some View {
        ZStack {
            if thread.type == .selfThread {
                let startColor = Color(red: 255/255, green: 145/255, blue: 98/255)
                let endColor = Color(red: 255/255, green: 90/255, blue: 113/255)
                Circle()
                    .foregroundColor(.clear)
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .background(LinearGradient(colors: [startColor, endColor], startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
                    .overlay {
                        Image("bookmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 27, height: 27)
                            .foregroundStyle(Color.App.textPrimary)
                    }
            } else if let image = computedImageURL {
                ImageLoaderView(
                    imageLoader: threadsVM.avatars(for: image, metaData: thread.metadata, userName: String.splitedCharacter(thread.title ?? "")),
                    textFont: .iransansBoldBody
                )
                .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(String.getMaterialColorByCharCode(str: thread.title ?? ""))
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            } else {
                Text(verbatim: String.splitedCharacter(thread.computedTitle))
                    .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                    .font(.iransansBoldSubheadline)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(String.getMaterialColorByCharCode(str: thread.title ?? ""))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
        }.task {
            /// We do this beacuse computedImageURL use metadata decoder and it should not be on the main thread.
            Task {
                computedImageURL = thread.computedImageURL
            }
        }
        .onReceive(thread.objectWillChange) { _ in /// update an image of a thread by another device
            if computedImageURL != self.thread.computedImageURL {
                self.computedImageURL = thread.computedImageURL
            }
        }
    }
}
