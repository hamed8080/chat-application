//
//  SelectThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct SelectThreadRow: View {
    var thread: Conversation
    @ObservedObject var imageLoader: ImageLoader
    var cancellableSet: Set<AnyCancellable> = []

    init(thread: Conversation) {
        self.thread = thread
        imageLoader = ImageLoader(url: thread.image ?? "", userName: thread.title ?? thread.inviter?.username, size: .SMALL)
        imageLoader.fetch()
    }

    var body: some View {
        HStack {
            imageLoader.imageView
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(18)
            Text(thread.title ?? "")
                .font(.headline)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
    }
}

struct SelectThreadRow_Previews: PreviewProvider {
    static var previews: some View {
        SelectThreadRow(thread: MockData.thread)
    }
}
