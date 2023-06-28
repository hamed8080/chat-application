//
//  CreateDirectThreadView.swift
//  ChatApplication
//
//  Created by hamed on 5/16/23.
//

import Chat
import ChatAppExtensions
import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI

struct DeleteThreadConfirmationView: View {
    @EnvironmentObject var viewModel: ThreadsViewModel

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "Delete \(viewModel.selectedThraed?.title ?? "")")
                SectionImageView(image: Image("delete"))
                Section {
                    Button {
                        if viewModel.sheetType == .firstConfrimation {
                            viewModel.sheetType = .secondConfirmation
                        } else if viewModel.sheetType == .secondConfirmation {
                            viewModel.delete()
                        }
                    } label: {
                        Label("\(viewModel.sheetType == .secondConfirmation ? "Permanently Delete" : "Confirm")".uppercased(), systemImage: "trash")
                            .foregroundColor(.red)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                    }
                    .font(.iransansSubheadline)
                    .buttonStyle(.bordered)
                } footer: {
                    Text("With deleting a thread, you cannot restore or join it again.")
                }
                .listRowBackground(Color.clear)
            }
            .animation(.easeInOut, value: viewModel.sheetType)
        }
    }
}

struct DeleteThreadConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteThreadConfirmationView()
            .environmentObject(ThreadsViewModel())
    }
}
