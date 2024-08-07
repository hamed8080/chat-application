//
//  Sticker+.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import TalkViewModels
import ChatModels
import SwiftUI
import TalkExtensions
import Chat
import ActionableContextMenu
import TalkUI

struct ReactionMenuView: View {
    @EnvironmentObject var reactionVM: ThreadReactionViewModel
    @EnvironmentObject var contextMenuVM: ContextMenuModel
    @EnvironmentObject var viewModel: MessageRowViewModel
    var selectedSticker: Sticker? { viewModel.reactionsModel.myReactionSticker }
    @State var show = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Sticker.allCases.filter({$0 != .unknown})) { sticker in
                    Button {
                        if let messageId = viewModel.message.id {
                            reactionVM.reaction(sticker, messageId: messageId)
                            contextMenuVM.hide()
                        }
                    } label: {
                        Text(verbatim: sticker.emoji)
                            .frame(width: 38, height: 38)
                            .font(.system(size: 32))
                            .padding(4)
                            .background(selectedSticker == sticker ? Color.App.accent.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius:(selectedSticker == sticker ? 22 : 0)))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(x: show ? 1.0 : 0.001, y: show ? 1.0 : 0.001, anchor: .center)
                    .transition(.scale)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.55, blendDuration: 0.3)) {
                                show = true
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .onTapGesture {} /// It's essential to disable the click of the context menu blur view.
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:(21)))
        .frame(maxWidth: 240)
    }
}

struct ReactionMenuView_Previews: PreviewProvider {
    struct Preview: View {
        static let message = Message(id: 1, message: "TEST", messageType: .text)
        @StateObject var viewModel = MessageRowViewModel(message: Preview.message, viewModel: ThreadViewModel(thread: Conversation(id: 1)))
        var body: some View {
            ReactionMenuView()
                .environmentObject(viewModel)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        viewModel.calMessage.state.showReactionsOverlay = true
                        viewModel.animateObjectWillChange()
                    }
                }
        }
    }

    static var previews: some View {
        VStack {
            Preview()
        }
        .frame(width: 196)
    }
}
