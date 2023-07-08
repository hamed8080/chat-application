//
//  MoveToBottomButton.swift
//  ChatApplication
//
//  Created by hamed on 7/7/23.
//

import ChatAppViewModels
import SwiftUI

struct MoveToBottomButton: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        Button {
            viewModel.scrollToBottom()
        } label: {
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding()
                .foregroundColor(Color.gray)
                .aspectRatio(contentMode: .fit)
                .contentShape(Rectangle())
        }
        .frame(width: 36, height: 36)
        .background(Color.white)
        .cornerRadius(36)
        .padding(.bottom, 16)
        .padding([.trailing], 8)
        .scaleEffect(x: viewModel.isAtBottomOfTheList ? 0.0 : 1.0, y: viewModel.isAtBottomOfTheList ? 0.0 : 1.0, anchor: .center)
        .overlay(alignment: .top) {
            let unreadCount = viewModel.thread?.unreadCount ?? 0
            let hide = unreadCount == 0
            Text(verbatim: unreadCount == 0 ? "" : "\(unreadCount)")
                .font(.system(size: 12))
                .fontDesign(.rounded)
                .frame(height: hide ? 0 : 24)
                .frame(minWidth: 24)
                .background(.orange)
                .foregroundColor(.white)
                .cornerRadius(hide ? 0 : 24)
                .offset(x: -3, y: -16)
                .animation(.easeInOut, value: unreadCount)
        }
    }
}

struct MoveToBottomButton_Previews: PreviewProvider {
    static var previews: some View {
        MoveToBottomButton()
    }
}
