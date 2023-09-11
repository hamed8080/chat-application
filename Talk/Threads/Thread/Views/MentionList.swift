//
//  MentionList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels

struct MentionList: View {
    @Binding var text: String
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if viewModel.mentionList.count > 0 {
            List(viewModel.mentionList) { participant in
                ParticipantRow(participant: participant)
                    .onTapGesture {
                        if let lastMatch = text.matches(char: "@")?.last {
                            let removeRange = text.last == "@" ? NSRange(text.index(text.endIndex, offsetBy: -1)..., in: text) : lastMatch.range
                            let removedText = text.remove(in: removeRange) ?? ""
                            text = removedText + "@" + (participant.username ?? "")
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
        } else {
            EmptyView()
        }
    }
}

struct MentionList_Previews: PreviewProvider {
    static var previews: some View {
        MentionList(text: .constant("John"))
    }
}
