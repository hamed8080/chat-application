//
//  CreateDirectThreadView.swift
//  Talk
//
//  Created by hamed on 5/16/23.
//

import Chat
import ChatModels
import Combine
import SwiftUI
import TalkExtensions
import TalkUI
import TalkViewModels

struct CreateDirectThreadView: View {
    @State private var type: InviteeTypes = .cellphoneNumber
    @State private var message: String = ""
    @State private var id: String = ""
    var onCompeletion: (Invitee, String) -> Void
    @State var types = InviteeTypes.allCases.filter { $0 != .unknown }

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "ThreadList.Toolbar.fastMessage")
                SectionImageView(image: Image("fast_message"))

                Section {
                    Picker("Contact type", selection: $type) {
                        ForEach(types) { value in
                            Text(.init(localized: .init(value.title)))
                                .foregroundColor(.primary)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    let typeString = String(localized: .init(type.title))
                    let fastMessge = String(localized: .init("Thread.enterFastMessageType"))
                    TextField(String(format: fastMessge, typeString), text: $id)
                        .keyboardType(type == .cellphoneNumber ? .phonePad : .default)

                    TextField("Thread.SendContainer.typeMessageHere", text: $message)
                } footer: {
                    Text("Thread.fastMessageFooter")
                }

                Button {
                    onCompeletion(Invitee(id: id, idType: type), message)
                } label: {
                    Label("General.send", systemImage: "paperplane")
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
