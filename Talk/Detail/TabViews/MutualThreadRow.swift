//
//  MutualThreadRow.swift
//  Talk
//
//  Created by hamed on 12/17/23.
//

import SwiftUI
import TalkModels
import TalkViewModels
import TalkUI
import Chat

struct MutualThreadRow: View {
    var thread: Conversation

    init(thread: Conversation) {
        self.thread = thread
    }

    var body: some View {
        HStack {
            let config = ImageLoaderConfig(url: thread.computedImageURL ?? "", userName: String.splitedCharacter(thread.title ?? ""))
            ImageLoaderView(imageLoader: .init(config: config))
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansSubtitle)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: thread.title ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(18)))
            Text(thread.computedTitle)
                .font(.iransansSubheadline)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    }
}

struct MutualThreadRow_Previews: PreviewProvider {
    static var previews: some View {
        MutualThreadRow(thread: .init(id: 1))
    }
}
