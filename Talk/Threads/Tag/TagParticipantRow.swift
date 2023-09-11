//
//  TagRow.swift
//  TagParticipantRow
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct TagParticipantRow: View {
    var tag: Tag
    var tagParticipant: TagParticipant
    @StateObject var viewModel: TagsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let thread = tagParticipant.conversation {
                        ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: tagParticipant.conversation?.computedImageURL, metaData: thread.metadata, userName: tagParticipant.conversation?.title)
                            .id("\(tagParticipant.conversation?.computedImageURL ?? "")\(tagParticipant.conversation?.id ?? 0)")
                            .font(.system(size: 16).weight(.heavy))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(14)
                        VStack(alignment: .leading) {
                            Text(thread.title ?? "")
                                .font(.iransansBody)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
    }
}

struct TagParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        TagParticipantRow(tag: MockData.tag, tagParticipant: MockData.tag.tagParticipants!.first!, viewModel: TagsViewModel())
    }
}
