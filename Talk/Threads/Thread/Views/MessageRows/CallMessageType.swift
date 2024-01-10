//
//  CallMessageType.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct CallMessageType: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 2) {
                Text(viewModel.callDateText)
                Text(viewModel.callTypeKey)
            }
            .foregroundStyle(Color.App.white)
            .font(.iransansBody)
            .padding(2)
            Image(systemName: message.type == .startCall ? "phone.arrow.up.right.fill" : "phone.down.fill")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: message.type == .startCall ? 12 : 18, height: message.type == .startCall ? 12 : 18)
                .foregroundStyle(message.type == .startCall ? Color.App.color2 : Color.App.red)
        }
        .padding(.horizontal, 16)
        .background(Color.App.textPrimary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius:(25)))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
