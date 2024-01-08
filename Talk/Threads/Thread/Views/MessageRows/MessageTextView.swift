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
        if !message.messageTitle.isEmpty, !viewModel.isPublicLink {
//            CustomUITextView(attributedText: NSAttributedString(viewModel.markdownTitle), textColor: UIColor(named: "text_primary")!)
            Text(viewModel.markdownTitle)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(EdgeInsets(top: !message.isImage && message.replyInfo == nil && message.forwardInfo == nil ? 6 : 0, leading: 6, bottom: 0, trailing: 6))
                .font(.iransansBody)
                .foregroundColor(Color.App.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } else if let fileName = message.uploadFileName, message.isUnsentMessage == true {
            Text(fileName)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(.horizontal, 6)
                .font(.iransansBody)
                .foregroundColor(Color.App.textPrimary)
        }
    }
}

struct MessageTextView_Previews: PreviewProvider {
    static var previews: some View {
        MessageTextView()
    }
}
