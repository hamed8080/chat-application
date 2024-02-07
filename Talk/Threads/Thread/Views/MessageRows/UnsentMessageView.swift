//
//  UnsentMessageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels

struct UnsentMessageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        if message.isUnsentMessage {
            HStack(spacing: 16) {
                Button("Messages.resend") {
                    threadVM?.unsentMessagesViewModel.resendUnsetMessage(message)
                }
                Button("General.cancel", role: .destructive) {
                    threadVM?.unsentMessagesViewModel.cancel(message.uniqueId)
                }
            }
            .padding(.horizontal, 6)
            .font(.iransansCaption.bold())
            .padding(.top, 10) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        }
    }
}

struct UnsentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        UnsentMessageView()
    }
}
