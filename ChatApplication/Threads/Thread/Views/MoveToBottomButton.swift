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
    @State private var isAtBottomOfTheList: Bool = true

    var body: some View {
        Button {
            viewModel.scrollToBottom()
            isAtBottomOfTheList = true
        } label: {
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: isAtBottomOfTheList ? 0 : 16, height: isAtBottomOfTheList ? 0 : 16)
                .padding()
                .foregroundColor(.primary)
                .aspectRatio(contentMode: .fit)
                .contentShape(Rectangle())
        }
        .frame(width: isAtBottomOfTheList ? 0 : 36, height: isAtBottomOfTheList ? 0 : 36)
        .background(.ultraThinMaterial)
        .cornerRadius(36)
        .shadow(color: .gray.opacity(0.4), radius: 10)
        .padding(.bottom, 16)
        .padding([.trailing], 8)
        .scaleEffect(x: isAtBottomOfTheList ? 0.0 : 1.0, y: isAtBottomOfTheList ? 0.0 : 1.0, anchor: .center)
        .animation(.easeInOut, value: isAtBottomOfTheList)
        .overlay(alignment: .top) {
            let unreadCount = viewModel.thread.unreadCount ?? 0
            let hide = unreadCount == 0 || isAtBottomOfTheList
            Text(verbatim: unreadCount == 0 ? "" : "\(viewModel.thread.unreadCountString ?? "")")
                .font(.system(size: 12))
                .fontDesign(.rounded)
                .frame(height: hide ? 0 : 24)
                .frame(minWidth: hide ? 0 : 24)
                .scaleEffect(x: hide ? 0.0 : 1.0, y: hide ? 0.0 : 1.0, anchor: .center)
                .background(.orange)
                .foregroundColor(.white)
                .cornerRadius(hide ? 0 : 24)
                .offset(x: -3, y: -16)
                .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: unreadCount)
        }
        .onReceive(viewModel.objectWillChange) { _ in
            if viewModel.isAtBottomOfTheList != isAtBottomOfTheList {
                isAtBottomOfTheList = viewModel.isAtBottomOfTheList
            }
        }
    }
}

struct MoveToBottomButton_Previews: PreviewProvider {
    static var vm = ThreadViewModel(thread: .init(id: 1))
    static var previews: some View {
        ZStack {
            MoveToBottomButton()
                .environmentObject(vm)
                .onAppear {
                    vm.isAtBottomOfTheList = false
                    vm.thread.unreadCount = 10
                    vm.animateObjectWillChange()
                }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}
