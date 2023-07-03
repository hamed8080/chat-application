//
//  ReplyInfoMessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ReplyInfoMessageRow: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @EnvironmentObject var calculation: MessageRowCalculationViewModel

    var body: some View {
        Button {
            if let time = message.replyInfo?.repliedToMessageTime, let repliedToMessageId = message.replyInfo?.repliedToMessageId {
                threadViewModel.moveToTime(time, repliedToMessageId)
            }
        } label: {
            HStack {
                Image(systemName: "poweron")
                    .resizable()
                    .frame(width: 3)
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .foregroundColor(.orange)
                VStack(spacing: 4) {
                    if let name = message.replyInfo?.participant?.name {
                        Text("\(name)")
                            .font(.iransansBoldCaption2)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: name.isEnglishString ? .leading : .trailing)
                            .foregroundColor(.orange)
                            .padding([.leading, .trailing], 4)
                    }

                    if let message = message.replyInfo?.message?.replacingOccurrences(of: "\n", with: " ") {
                        Text(message)
                            .font(.iransansCaption3)
                            .padding([.leading, .trailing], 4)
                            .cornerRadius(8, corners: .allCorners)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: message.isEnglishString ? .leading : .trailing)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: calculation.widthOfRow - 32, height: 48)
        .background(Color.replyBg)
        .cornerRadius(8)
        .padding([.top, .leading, .trailing], 12)
        .truncationMode(.tail)
        .lineLimit(1)
        .onAppear {
            calculation.calculate(message: message)
        }
    }
}
