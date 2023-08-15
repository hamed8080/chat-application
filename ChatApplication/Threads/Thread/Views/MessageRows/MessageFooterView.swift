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
    @State var timeString: String = ""
    @EnvironmentObject var calculation: MessageRowViewModel

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

            if message.edited == true {
                Text("Messages.Footer.edited")
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption2)
            }

            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(message.footerStatus.fgColor)
                    .font(.subheadline)
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
        .padding(.top, 4)
    }
}
