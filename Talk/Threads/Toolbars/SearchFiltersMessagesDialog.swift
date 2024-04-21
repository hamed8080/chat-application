//
//  SearchFiltersMessagesDialog.swift
//  Talk
//
//  Created by hamed on 2/27/24.
//

import Foundation
import ChatModels
import TalkViewModels
import SwiftUI
import TalkUI

struct SearchFiltersMessagesDialog: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State private var showUnreadConversationToggle: Bool = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text("SearchFiltersMessagesDialog.filter")
                    .foregroundColor(Color.App.textPrimary)
                Spacer()
            }
            unreadToggle
            HStack {

                Button {
                    withAnimation {
                        viewModel.showUnreadConversations = showUnreadConversationToggle
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.submit")
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    withAnimation {
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
        .onAppear {
           showUnreadConversationToggle = viewModel.showUnreadConversations == true
        }
    }

    private var unreadToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color.App.iconSecondary)
            Text("SearchFiltersMessagesDialog.showUnreadConversations")
                .foregroundColor(Color.App.textPrimary)
                .lineLimit(1)
                .layoutPriority(1)
            Toggle("", isOn: $showUnreadConversationToggle)
                .scaleEffect(x: 0.8, y: 0.8, anchor: .center)
                .offset(x: -12)
        }
        .padding(.horizontal)
        .toggleStyle(MyToggleStyle())
    }
}

struct SearchFiltersMessagesDialog_Previews: PreviewProvider {
    static var previews: some View {
        SearchFiltersMessagesDialog()
            .environmentObject(ContactsViewModel())
    }
}
