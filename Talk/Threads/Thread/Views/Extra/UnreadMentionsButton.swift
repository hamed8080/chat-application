//
//  UnreadMentionsButton.swift
//  Talk
//
//  Created by hamed on 11/29/23.
//

import SwiftUI
import TalkViewModels

struct UnreadMentionsButton: View {
    @EnvironmentObject var viewModel: ThreadUnreadMentionsViewModel
    @EnvironmentObject var threadVM: ThreadViewModel
    @State private var timerToUpdate: Timer?
    var hasMention: Bool { threadVM.thread.mentioned ?? false }

    var body: some View {
        if hasMention {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        threadVM.scrollVM.scrollingUP = false//open sending unread counts if we scrolled up and there is a new messge where we have mentiond
                        threadVM.moveToFirstUnreadMessage()
                    }
                } label: {
                    Text("@")
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundStyle(Color.App.accent)
                        .contentShape(Rectangle())
                }
                .frame(width: 40, height: 40)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
                .shadow(color: .gray.opacity(0.4), radius: 2)
                .overlay(alignment: .top) {
                    let unreadCount = viewModel.unreadMentions.count
                    Text(verbatim: "\(unreadCount)")
                        .font(.iransansBoldCaption)
                        .frame(height: 24)
                        .frame(minWidth: 24)
                        .background(Color.App.accent)
                        .foregroundStyle(Color.App.white)
                        .clipShape(RoundedRectangle(cornerRadius:(24)))
                        .offset(x: 0, y: -16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: unreadCount)
                }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}

struct UnreadMentionsButton_Previews: PreviewProvider {
    static var previews: some View {
        UnreadMentionsButton()
    }
}
