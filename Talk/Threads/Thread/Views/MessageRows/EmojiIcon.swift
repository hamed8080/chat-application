//
//  EmojiIcon.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import ChatAppViewModels
import SwiftUI

struct EmojiIcon: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @State private var showReactionDetail = false

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "face.smiling.inverse")
                    .frame(width: 36, height: 36)
                    .foregroundColor(.orange)
                    .offset(x: -8)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            viewModel.showReactionsOverlay.toggle()
                            viewModel.animateObjectWillChange()
                        }
                    }
                    .onLongPressGesture {
                        withAnimation(.easeInOut) {
                            showReactionDetail = true
                        }
                    }
                    .navigationDestination(isPresented: $showReactionDetail) {
                        if showReactionDetail {
                            MessageReactionDetailView(message: viewModel.message)
                        }
                    }
            }
            Spacer()
        }
    }
}

struct EmojiIcon_Previews: PreviewProvider {
    static var previews: some View {
        EmojiIcon()
            .environmentObject(MessageRowViewModel(message: .init(id: 1, message: "TEST"), viewModel: .init(thread: .init(id: 1))))
    }
}
