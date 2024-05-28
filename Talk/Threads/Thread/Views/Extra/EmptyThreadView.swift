//
//  EmptyThreadView.swift
//  Talk
//
//  Created by hamed on 3/7/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct EmptyThreadView: View {
    @EnvironmentObject private var viewModel: ThreadHistoryViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEmptyThread = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("Thread.noMessage")
                        .font(.iransansSubtitle)
                        .foregroundStyle(Color.App.textPrimary)
                        .fontWeight(.regular)
                    Image(systemName: "text.bubble")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Color.App.accent)
                }
                .padding(48)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
            Spacer()
        }
        .frame(height: isEmptyThread ? nil : 0)
        .opacity(isEmptyThread ? 1.0 : 0.0)
        .contentShape(Rectangle())
        .clipped()
        .onReceive(viewModel.objectWillChange) { _ in
            Task {
                isEmptyThread = await viewModel.isEmptyThread
            }
        }
    }
}

struct EmptyThreadView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyThreadView()
            .environmentObject(ThreadHistoryViewModel())
    }
}
