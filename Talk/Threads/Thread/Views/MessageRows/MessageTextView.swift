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

    // We have to check hasText here, due to there is a chance the user add to a peice of text to a file message.
    var body: some View {
        if viewModel.rowType.hasText {
            // TODO: TEXT must be alignment and image must be fit
            Text(viewModel.calculatedMessage.markdownTitle)
                .multilineTextAlignment(viewModel.calculatedMessage.isEnglish ? .leading : .trailing)
                .lineSpacing(8)
                .padding(viewModel.sizes.paddings.textViewPadding)
                .font(.iransansBody)
                .foregroundColor(Color.App.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, viewModel.sizes.paddings.textViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
                .background(viewModel.calculatedMessage.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
        }
    }
}

struct MessageTextView_Previews: PreviewProvider {
    static var previews: some View {
        MessageTextView()
    }
}
