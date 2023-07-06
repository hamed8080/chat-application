//
//  MessageFooterView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageFooterView: View {
    var message: Message
    // We never use this viewModel but it will refresh view when a event on this message happened such as onSent, onDeliver,onSeen.
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var timeString: String = ""
    @EnvironmentObject var calculation: MessageRowCalculationViewModel

    var body: some View {
        HStack {
            if let fileSize = calculation.fileSizeString {
                Text(fileSize)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBody)
                    .foregroundColor(.darkGreen.opacity(0.8))
            }
            Spacer()
            Text(calculation.timeString)
                .foregroundColor(.darkGreen.opacity(0.8))
                .font(.iransansBoldCaption2)
            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(message.footerStatus.fgColor)
                    .font(.subheadline)
            }

            if message.edited == true {
                Text("Edited")
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption2)
            }

            if message.pinned == true {
                Image(systemName: "pin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.orange)
                    .font(.subheadline)
            }
        }
        .animation(.easeInOut, value: message.delivered)
        .animation(.easeInOut, value: message.seen)
        .animation(.easeInOut, value: message.edited)
        .padding(.top, 4)
    }
}
