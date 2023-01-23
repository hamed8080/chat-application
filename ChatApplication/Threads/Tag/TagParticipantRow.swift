//
//  TagRow.swift
//  TagParticipantRow
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct TagParticipantRow: View {
    var tag: Tag
    var tagParticipant: TagParticipant
    @ObservedObject var viewModel: TagsViewModel

    init(tag: Tag, tagParticipant: TagParticipant, viewModel: TagsViewModel) {
        self.tag = tag
        self.tagParticipant = tagParticipant
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let thread = tagParticipant.conversation {
                        ImageLaoderView(url: tagParticipant.conversation?.computedImageURL, userName: tagParticipant.conversation?.title)
                            .font(.system(size: 16).weight(.heavy))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(14)
                        VStack(alignment: .leading) {
                            Text(thread.title ?? "")
                                .font(.headline)
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
