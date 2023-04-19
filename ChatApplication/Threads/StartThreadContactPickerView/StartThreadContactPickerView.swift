//
//  StartThreadContactPickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import Combine
import SwiftUI

struct StartThreadContactPickerView: View {
    @EnvironmentObject var contactsVM: ContactsViewModel
    var onCompletedConfigCreateThread: (StartThreadResultModel) -> Void
    @StateObject var model: StartThreadResultModel = .init()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.showGroupTitleView {
                HStack {
                    Spacer()
                    Button {
                        if model.hasError { return }
                        model.selectedContacts.append(contentsOf: contactsVM.selectedContacts)
                        onCompletedConfigCreateThread(model.build)
                    } label: {
                        Label("Create", systemImage: "plus.square")
                    }
                    .foregroundColor(.green)
                }
                .padding()
            }

            Group {
                StartThreadButton(name: "bookmark.circle", title: "Save Message", color: .blue) {
                    model.setSelfThread()
                    onCompletedConfigCreateThread(model.build)
                }

                StartThreadButton(name: "person.2", title: "New Group", color: .blue) {
                    model.toggleGroup()
                }

                StartThreadButton(name: "megaphone", title: "New Channel", color: .blue) {
                    model.toggleChannel()
                }

                if model.showGroupTitleView {
                    HStack {
                        MultilineTextField("Enter group name", text: $model.title, backgroundColor: Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(model.hasError ? Color.red : model.isPublicNameAvailable ? .green : .clear, lineWidth: 1)
                            )
                            .padding([.leading, .trailing])
                        if model.isCehckingName {
                            LoadingView(isAnimating: model.isCehckingName, width: 2)
                                .frame(width: 18, height: 18)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if model.isPublic {
                        Text("Public threads are available to everyone on the internet.")
                            .transition(.push(from: .bottom))
                        Text("Public threads names should have a unique names without any whitespace and special characters.")
                            .transition(.push(from: .bottom))
                    }

                    if model.hasError {
                        Text("Enter the name of the conversation.")
                            .transition(.push(from: .bottom))
                            .foregroundColor(.red)
                    }
                }
                .padding([.leading, .trailing])
                .padding(.top, 8)
                .foregroundColor(.gray)
                .font(.caption)

                if model.type == .channel || model.isGroup {
                    Toggle("Public", isOn: $model.isPublic)
                        .padding()
                }
            }
            .padding([.leading, .trailing])
            .noSeparators()

            List {
                ForEach(contactsVM.contacts) { contact in
                    StartThreadContactRow(isInMultiSelectMode: $model.isInMultiSelectMode, contact: contact)
                        .onTapGesture {
                            if model.isInMultiSelectMode == false {
                                model.selectedContacts.append(contact)
                                onCompletedConfigCreateThread(model.build)
                            }
                        }
                        .onAppear {
                            if contactsVM.contacts.last == contact {
                                contactsVM.loadMore()
                            }
                        }
                }
            }
            .listStyle(.insetGrouped)
            .overlay(alignment: .bottom) {
                ListLoadingView(isLoading: $contactsVM.isLoading)
                    .padding(.bottom)
            }
        }
        .animation(.easeInOut, value: model.isCehckingName)
        .animation(.easeInOut, value: model.isPublic)
        .animation(.easeInOut, value: model.isInMultiSelectMode)
        .padding(0)
    }
}

struct StartThreadButton: View {
    var name: String
    var title: String
    var color: Color
    var action: (() -> Void)?

    @State var isActive = false

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Image(systemName: name)
                Text(title)
                Spacer()
            }
        }
        .padding()
        .foregroundColor(.blue)
    }
}

struct StartThreadContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView { _ in }
            .environmentObject(contactVM)
            .preferredColorScheme(.dark)
    }
}
