//
//  MessageFooterView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct MessageFooterView: View {
    var message: any HistoryMessageProtocol { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    private var thread: Conversation? { threadVM?.thread }

    var body: some View {
        HStack(spacing: 0) {
            if !viewModel.calMessage.isMe {
                timeView
            }
            editedText
            if viewModel.calMessage.isMe {
                timeView
            }
            StatusIcon()
            pinImage
        }
        .font(.subheadline)
        .padding(EdgeInsets(top: 4, leading: 6, bottom: 0, trailing: -4)) /// Top 4 for spacing in VStack in TextMessageType
    }

    private var timeView: some View {
        Text(viewModel.calMessage.timeString)
            .foregroundColor(Color.App.textPrimary.opacity(0.5))
            .font(.iransansCaption2)
            .fontWeight(.medium)
            .padding(.horizontal, 2)
    }

    private var editedText: some View {
        Text("Messages.Footer.edited")
            .foregroundColor(Color.App.textSecondary)
            .font(.iransansCaption2)
            .frame(width: message.edited == true ? nil : 0, height: message.edited == true ? nil : 0)
            .clipped()
            .padding(.leading, 2)
    }

    @ViewBuilder
    private var pinImage: some View {
        let isPin = message.id != nil && message.id == thread?.pinMessage?.id
        Image(systemName: "pin.fill")
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: isPin ? 12 : 0, height: isPin ? 12 : 0)
            .foregroundColor(Color.App.accent)
            .padding(.trailing, 2)
    }
}
