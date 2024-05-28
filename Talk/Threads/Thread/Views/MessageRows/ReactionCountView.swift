//
//  ReactionCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

struct ReactionCountView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.reactionsModel.rows) { row in
                    ReactionCountRow(row: row)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(.easeInOut, value: viewModel.reactionsModel.rows.count)
        .padding(.horizontal, 6)
        .padding(.top, viewModel.reactionsModel.topPadding) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
    }
}

struct ReactionCountRow: View {
    @EnvironmentObject var reactionVM: ThreadReactionViewModel
    @EnvironmentObject var viewModel: MessageRowViewModel
    let row: ReactionRowsCalculated.Row

    var body: some View {
        HStack {
            Text(verbatim: row.emoji)
                .frame(width: 20, height: 20)
                .font(.system(size: 14))
                .clipped()
            Text(row.countText)
                .font(.iransansBody)
                .foregroundStyle(row.isMyReaction ? Color.App.white : Color.App.textPrimary)
        }
        .padding(row.edgeInset)
        .background(
            Rectangle()
                .fill(row.isMyReaction ? Color.App.color1.opacity(0.9) : Color.App.accent.opacity(0.1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            onReactionTapped()
        }
        .customContextMenu(id: row.reactionId, self: self.environmentObject(viewModel)) {
            contextMenu
        }
    }

    private func onReactionTapped() {
        if let tappedStciker = row.sticker {
            reactionVM.reaction(tappedStciker, messageId: viewModel.message.id ?? -1)
        }
    }

    private var contextMenu: some View {
        let tabVM = ReactionTabParticipantsViewModel(messageId: viewModel.message.id ?? -1)
        tabVM.viewModel = viewModel.threadVM?.reactionViewModel
        return MessageReactionDetailView(message: viewModel.message, row: row)
            .environmentObject(tabVM)
            .environmentObject(viewModel.threadVM?.reactionViewModel ?? .init())
            .frame(width: 300, height: 400)
            .clipShape(RoundedRectangle(cornerRadius:(12)))
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView()
    }
}
