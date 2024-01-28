//
//  DeleteMessageDialog.swift
//  
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

public struct DeleteMessageDialog: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    let threadVM: ThreadViewModel
    var viewModel: ThreadSelectedMessagesViewModel { threadVM.selectedMessagesViewModel }
    private var messages: [Message] { viewModel.selectedMessages.compactMap({$0.message}) }
    private let deleteForMe: Bool
    private let deleteForOthers: Bool
    private var hasPinnedMessage: Bool { messages.contains(where: {$0.id == threadVM.thread.pinMessage?.id })}
    /// 86_400_000 is equal to the number of milliseconds in a day
    private var pastDeleteTimeForOthers: [Message] { messages.filter({ Int64($0.time ?? 0) + (86_400_000) < Date().millisecondsSince1970 }) }

    public init(deleteForMe: Bool, deleteForOthers: Bool, viewModel: ThreadViewModel) {
        self.deleteForMe = deleteForMe
        self.deleteForOthers = deleteForOthers
        self.threadVM = viewModel
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("DeleteMessageDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("DeleteMessageDialog.subtitle")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBody)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            let isSingle = messages.count == 1
            if hasPinnedMessage {
                Text(isSingle ? "DeleteMessageDialog.singleDeleteIsPinMessage" : "DeleteMessageDialog.multipleDeleteContainsPinMessage")
                    .foregroundStyle(Color.App.textSecondary)
                    .font(.iransansCaption2)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                if pastDeleteTimeForOthers.isEmpty {
                    HStack(spacing: 16) {
                        buttons
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        buttons
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }

    @ViewBuilder var buttons: some View {
        if deleteForMe {
            Button {
                threadVM.historyVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}))
                threadVM.isInEditMode = false
                appOverlayVM.dialogView = nil
                viewModel.animateObjectWillChange()
            } label: {
                Text("Messages.deleteForMe")
                    .foregroundStyle(Color.App.accent)
                    .font(.iransansBoldCaption)
            }
        }

        if deleteForOthers, !hasPinnedMessage, pastDeleteTimeForOthers.isEmpty {
            Button {
                threadVM.historyVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}), forAll: true)
                threadVM.isInEditMode = false
                appOverlayVM.dialogView = nil
                viewModel.animateObjectWillChange()
            } label: {
                Text("Messages.deleteForAll")
                    .foregroundStyle(Color.App.red)
                    .font(.iransansBoldCaption)
            }
        } else if deleteForOthers, !pastDeleteTimeForOthers.isEmpty {
            Button {
                let notPastDeleteTime = messages.filter({!pastDeleteTimeForOthers.contains($0)})
                if pastDeleteTimeForOthers.count > 0 {
                    threadVM.historyVM.deleteMessages(pastDeleteTimeForOthers, forAll: false)
                }
                if notPastDeleteTime.count > 0 {
                    threadVM.historyVM.deleteMessages(notPastDeleteTime, forAll: true)
                }
                threadVM.isInEditMode = false
                appOverlayVM.dialogView = nil
                viewModel.animateObjectWillChange()
            } label: {
                Text("DeleteMessageDialog.deleteForMeAllOtherIfPossible")
                    .foregroundStyle(Color.App.red)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBoldCaption)
            }
        }

        Button {
            viewModel.clearSelection()
            threadVM.isInEditMode = false
            appOverlayVM.dialogView = nil
            viewModel.animateObjectWillChange()
        } label: {
            Text("General.cancel")
                .foregroundStyle(Color.App.textPlaceholder)
                .font(.iransansBoldCaption)
        }
    }
}

struct DeleteMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteMessageDialog(deleteForMe: false, deleteForOthers: false, viewModel: .init(thread: Conversation(id: 1)))
    }
}
