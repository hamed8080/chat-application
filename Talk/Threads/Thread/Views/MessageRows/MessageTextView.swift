//
//  MessageTextView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import ChatModels
import TalkViewModels

struct MessageTextView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        // TODO: TEXT must be alignment and image must be fit
        if !message.messageTitle.isEmpty, message.forwardInfo == nil, !message.isPublicLink {
            Text(viewModel.markdownTitle)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(.horizontal, 6)
                .font(.iransansBody)
                .foregroundColor(Color.App.text)
                .fixedSize(horizontal: false, vertical: true)
        } else if let fileName = message.fileName, message.isUnsentMessage == true {
            Text(fileName)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(.horizontal, 6)
                .font(.iransansBody)
                .foregroundColor(Color.App.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MessageTextView_Previews: PreviewProvider {
    static var previews: some View {
        MessageTextView()
    }
}
