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
    var message: Message
    @State var timeString: String = ""
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            if let fileSize = viewModel.fileSizeString {
                Text(fileSize)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBody)
                    .foregroundColor(.darkGreen.opacity(0.8))
            }
            Spacer()
            Text(viewModel.timeString)
                .foregroundColor(.darkGreen.opacity(0.8))
                .font(.iransansBoldCaption2)

            if message.edited == true {
                Text("Messages.Footer.edited")
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption2)
            }

            if viewModel.isMe {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(message.footerStatus.fgColor)
                    .font(.subheadline)
            }

            let isPinned = message.id == viewModel.threadVM?.thread.pinMessage?.id
            Image(systemName: "pin")
                .resizable()
                .scaledToFit()
                .frame(width: isPinned ? 14 : 0, height: isPinned ? 14 : 0)
                .foregroundColor(.orange)
                .font(.subheadline)
        }
        .padding(.top, 4)
    }
}