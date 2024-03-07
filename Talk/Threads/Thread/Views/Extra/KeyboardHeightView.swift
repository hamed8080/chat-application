//
//  KeyboardHeightView.swift
//  Talk
//
//  Created by hamed on 3/7/24.
//

import SwiftUI
import TalkViewModels
import Chat

struct KeyboardHeightView: View {
    @EnvironmentObject private var viewModel: ThreadScrollingViewModel
    /// We use isInAnimating to prevent multiple calling onKeyboardSize.
    @State private var isInAnimating = false

    var body: some View {
        Rectangle()
            .id("KeyboardHeightView")
            .frame(width: 0, height: 0)
            .onKeyboardSize { size in
                if !isInAnimating {
                    isInAnimating = true
                    viewModel.disableExcessiveLoading()
                    if size.height > 0, viewModel.isAtBottomOfTheList {
                        updateHeight(size.height)
                    } else if viewModel.isAtBottomOfTheList {
                        updateHeight(size.height)
                    } else {
                        isInAnimating = false
                    }
                }
            }
            .onReceive(NotificationCenter.message.publisher(for: .message)) { notif in
                if let event = notif.object as? MessageEventTypes {
                    if case .new(let response) = event, response.result?.conversation?.id == viewModel.threadVM?.threadId, viewModel.isAtBottomOfTheList {
                        updateHeight(0)
                    }
                }
            }
    }

    private func updateHeight(_ height: CGFloat) {
        // We have to wait until all the animations for clicking on TextField are finished and then start our animation.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.4).delay(0.5)) {
                viewModel.scrollToBottom()
                isInAnimating = false
            }
        }
    }
}

struct KeyboardHeightView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardHeightView()
            .environmentObject(ThreadViewModel(thread: .init(id: 0)).scrollVM)
    }
}
