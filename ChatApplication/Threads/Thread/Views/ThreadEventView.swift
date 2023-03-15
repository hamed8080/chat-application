//
//  ThreadEventView.swift
//  ChatApplication
//
//  Created by hamed on 11/30/22.
//

import FanapPodChatSDK
import SwiftUI

struct ThreadEventView: View {
    @EnvironmentObject var viewModel: ThreadEventViewModel
    var smt: SMT { viewModel.smt ?? .unknown }

    var body: some View {
        if let event = smt.titleAndIcon {
            HStack {
                Image(systemName: event.image)
                    .resizable()
                    .foregroundColor(.orange)
                    .frame(width: 16, height: 16)

                Text(event.title)
                    .lineLimit(1)
                    .font(.iransansBoldCaption2)
                    .foregroundColor(.orange)
            }
            .frame(height: viewModel.isShowingEvent ? 16 : 0)
            .animation(.spring(), value: viewModel.isShowingEvent)
        }
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadEventView()
            .environmentObject(ThreadEventViewModel(threadId: -1))
    }
}
