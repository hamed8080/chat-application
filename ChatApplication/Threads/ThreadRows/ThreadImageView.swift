//
//  ThreadImageView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatAppUI
import ChatModels
import SwiftUI

struct ThreadImageView: View {
    @State var thread: Conversation
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
        } else {
            ImageLaoderView(url: thread.computedImageURL, metaData: thread.metadata, userName: thread.title)
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
        }
    }
}
