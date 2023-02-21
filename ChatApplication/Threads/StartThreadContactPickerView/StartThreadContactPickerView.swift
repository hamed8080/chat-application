//
//  StartThreadContactPickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct StartThreadResultModel {
    var selectedContacts: [Contact]?
    var type: ThreadTypes = .normal
    var title: String = ""
}

struct StartThreadContactPickerView: View {
    @EnvironmentObject var contactsVM: ContactsViewModel
    @State private var isInMultiSelectMode = false
    var onCompletedConfigCreateThread: (StartThreadResultModel) -> Void
    @State var startThreadModel: StartThreadResultModel = .init()
    @State private var showGroupTitleView: Bool = false
    @State private var showEnterGroupNameError: Bool = false
    @State private var groupTitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                backButton()
                Spacer()
                nextButton()
            }
            .padding()

            if showGroupTitleView {
                VStack {
                    MultilineTextField("Enter group name", text: $groupTitle, backgroundColor: Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(showEnterGroupNameError ? Color.red : Color.clear, lineWidth: 1)
                        )
                }
                .padding([.leading, .trailing, .top], 16)
                Spacer()
            } else {
                StartThreadButton(name: "bookmark.circle", title: "Save Message", color: .blue) {
                    onCompletedConfigCreateThread(.init(selectedContacts: nil, type: .selfThread, title: ""))
                }

                StartThreadButton(name: "person.2", title: "New Group", color: .blue) {
                    isInMultiSelectMode.toggle()
                    startThreadModel.type = .channelGroup
                }

                StartThreadButton(name: "megaphone", title: "New Channel", color: .blue) {
                    isInMultiSelectMode.toggle()
                    startThreadModel.type = .channel
                }
                List {
                    ForEach(contactsVM.contacts) { contact in
                        StartThreadContactRow(isInMultiSelectMode: $isInMultiSelectMode, contact: contact)
                            .onTapGesture {
                                if isInMultiSelectMode == false {
                                    onCompletedConfigCreateThread(.init(selectedContacts: [contact], type: .normal, title: ""))
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
        }
        .padding(0)
    }

    @ViewBuilder
    func backButton() -> some View {
        if showGroupTitleView {
            Button {
                withAnimation {
                    showGroupTitleView = false
                }
            } label: {
                Text(showGroupTitleView == true ? "Back" : "")
            }
        }
    }

    @ViewBuilder
    func nextButton() -> some View {
        if isInMultiSelectMode {
            Button {
                withAnimation {
                    if showGroupTitleView == true {
                        if groupTitle.isEmpty {
                            showEnterGroupNameError = true
                        } else {
                            onCompletedConfigCreateThread(.init(selectedContacts: contactsVM.selectedContacts, type: startThreadModel.type, title: groupTitle))
                        }
                    } else {
                        showGroupTitleView.toggle()
                    }
                }
            } label: {
                Text(showGroupTitleView == false ? "Next" : "Create")
            }
        }
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
