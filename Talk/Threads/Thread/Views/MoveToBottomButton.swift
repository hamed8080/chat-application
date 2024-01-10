//
//  MoveToBottomButton.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct MoveToBottomButton: View {
    @EnvironmentObject var viewModel: ThreadScrollingViewModel

    var body: some View {
        if viewModel.isAtBottomOfTheList == false {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        viewModel.scrollToBottom()
                        viewModel.isAtBottomOfTheList = true
                        viewModel.animateObjectWillChange()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundStyle(Color.App.accent)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
                .shadow(color: .gray.opacity(0.4), radius: 2)
                .scaleEffect(x: 1.0, y: 1.0, anchor: .center)
                .overlay(alignment: .top) {
                    UnreadCountOverMoveToButtonView()
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        }
    }
}

struct UnreadCountOverMoveToButtonView: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        let unreadCount = viewModel.thread.unreadCount ?? 0
        let hide = unreadCount == 0
        Text(verbatim: unreadCount == 0 ? "" : "\(viewModel.thread.unreadCountString ?? "")")
            .font(.iransansBoldCaption)
            .frame(height: hide ? 0 : 24)
            .frame(minWidth: hide ? 0 : 24)
            .scaleEffect(x: hide ? 0.0001 : 1.0, y: hide ? 0.0001 : 1.0, anchor: .center)
            .background(Color.App.accent)
            .foregroundStyle(Color.App.white)
            .clipShape(RoundedRectangle(cornerRadius:(hide ? 0 : 24)))
            .offset(x: 0, y: -16)
            .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: unreadCount)
    }
}

struct MoveToBottomButton_Previews: PreviewProvider {
    static var vm = ThreadViewModel(thread: .init(id: 1))
    static var previews: some View {
        ZStack {
            MoveToBottomButton()
                .environmentObject(vm)
                .onAppear {
                    vm.scrollVM.isAtBottomOfTheList = false
                    vm.thread.unreadCount = 10
                    vm.animateObjectWillChange()
                }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}
