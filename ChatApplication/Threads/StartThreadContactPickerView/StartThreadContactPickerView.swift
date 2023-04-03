//
//  StartThreadContactPickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import Combine
import SwiftUI

class StartThreadResultModel: ObservableObject {
    @Published var selectedContacts: [Contact]
    @Published var type: ThreadTypes
    @Published var title: String
    @Published var isPublic: Bool
    @Published var isGroup: Bool
    @Published var isInMultiSelectMode: Bool
    @Published var isPublicNameAvailable: Bool
    @Published var isCehckingName: Bool = false
    var showGroupTitleView: Bool { isGroup || type == .channel }
    var hasError: Bool { !titleIsValid }
    private(set) var canceableSet: Set<AnyCancellable> = []

    init(selectedContacts: [Contact] = [],
         type: ThreadTypes = .normal,
         title: String = "",
         isPublic: Bool = false,
         isGroup: Bool = false,
         isInMultiSelectMode: Bool = false,
         isPublicNameAvailable: Bool = false)
    {
        self.selectedContacts = selectedContacts
        self.type = type
        self.title = title
        self.isPublic = isPublic
        self.isGroup = isGroup
        self.isInMultiSelectMode = isInMultiSelectMode
        self.isPublicNameAvailable = isPublicNameAvailable

        $title
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] publicName in
                self?.checkPublicName(publicName)
            }
            .store(in: &canceableSet)
    }

    var titleIsValid: Bool {
        if showGroupTitleView, title.isEmpty { return false }
        if !isPublic { return true }
        let regex = try! Regex("^[a-zA-Z0-9]\\S*$")
        return title.contains(regex)
    }

    var computedType: ThreadTypes {
        if !isPublic {
            return type
        } else if type == .channel, isPublic {
            return .publicChannel
        } else if isGroup, isPublic {
            return .publicGroup
        } else {
            return .normal
        }
    }

    var build: StartThreadResultModel { StartThreadResultModel(selectedContacts: selectedContacts, type: computedType, title: showGroupTitleView ? title : "", isPublic: isPublic, isGroup: isGroup) }

    func setSelfThread() {
        type = .selfThread
        resetSelection()
    }

    func toggleGroup() {
        if isGroup {
            resetSelection()
        } else {
            isInMultiSelectMode = true
            isGroup = true
            type = .normal
        }
    }

    func toggleChannel() {
        if type == .channel {
            type = .normal
            resetSelection()
        } else {
            type = .channel
            isInMultiSelectMode = true
        }
    }

    func resetSelection() {
        selectedContacts = []
        isInMultiSelectMode = false
        isGroup = false
        isPublic = false
    }

    func checkPublicName(_ title: String) {
        if titleIsValid {
            isCehckingName = true
            ChatManager.activeInstance?.isThreadNamePublic(.init(name: title)) { [weak self] result in
                if title == result.result?.name {
                    self?.isPublicNameAvailable = true
                }
                self?.isCehckingName = false
            }
        }
    }
}

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
