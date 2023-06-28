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

struct CreateDirectThreadView: View {
    @State private var type: InviteeTypes = .cellphoneNumber
    @State private var message: String = ""
    @State private var id: String = ""
    var onCompeletion: (Invitee, String) -> Void
    @State var types = InviteeTypes.allCases.filter { $0 != .unknown }

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "Fast Message")
                SectionImageView(image: Image("fast_message"))

                Section {
                    Picker("Contact type", selection: $type) {
                        ForEach(types) { value in
                            Text(verbatim: "\(value.title)")
                                .foregroundColor(.primary)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Enter \(type.title) here...", text: $id)
                        .keyboardType(type == .cellphoneNumber ? .phonePad : .default)

                    TextField("Enter your message here...", text: $message)
                } footer: {
                    Text("Create a thread immediately even though the person you are going to send a message to is not in the contact list.")
                }

                Button {
                    onCompeletion(Invitee(id: id, idType: type), message)
                } label: {
                    Label("Send".uppercased(), systemImage: "paperplane")
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                }
                .font(.iransansSubheadline)
            }
        }
    }
}

struct CreateDirectThreadView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDirectThreadView { _, _ in }
    }
}
