//
//  MessageFooterView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct MessageFooterView: View {
    var message: Message { viewModel.message }
    @State var timeString: String = ""
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            if message.forwardInfo != nil {
                Image(systemName: "arrow.turn.up.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color.App.gray5)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Text(viewModel.timeString)
                .foregroundColor(Color.App.hint)
                .font(.iransansCaption2)

            if message.edited == true {
                Text("Messages.Footer.edited")
                    .foregroundColor(Color.App.hint)
                    .font(.iransansCaption2)
            }

            if viewModel.isMe {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(message.footerStatus.fgColor)
                    .font(.subheadline)
            }

            if message.id == viewModel.threadVM?.thread.pinMessage?.id {
                Image(systemName: "pin.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color.App.primary)
                    .font(.subheadline)
            }
        }
        .padding(.top, 4)
        .padding(.horizontal, 6)
    }
}
