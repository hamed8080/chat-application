//
//  KeyboardResponsiveModifier.swift
//  ChatApplication
//
//  Created by Hamed on 1/15/22.
//

import SwiftUI

struct NavigateToThreadModifier: ViewModifier {
    @EnvironmentObject var appState: AppState

    func body(content: Content) -> some View {
        ZStack {
            content
            if let thread = appState.selectedThread {
                NavigationLink(destination: ThreadView(thread: thread), isActive: $appState.showThreadView) {
                    EmptyView()
                        .frame(width: 0, height: 0)
                        .hidden()
                }
                .frame(width: 0, height: 0)
                .hidden()
            }
        }
    }
}

extension View {
    func autoNavigateToThread() -> ModifiedContent<Self, NavigateToThreadModifier> {
        modifier(NavigateToThreadModifier())
    }
}
