//
//  StartThreadContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct StartThreadContactRow: View {
    @State private var isSelected = false
    @Binding public var isInMultiSelectMode: Bool
    @EnvironmentObject var viewModel: ContactsViewModel
    var contact: Contact

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 0, content: {
                    if isInMultiSelectMode {
                        Image(systemName: isSelected ? "checkmark.circle" : "circle")
                            .font(.title3)
                            .frame(width: 16, height: 16, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .onTapGesture {
                                isSelected.toggle()
                                viewModel.toggleSelectedContact(contact: contact)
                            }
                    }

                    ImageLaoderView(url: contact.image ?? contact.user?.image, userName: contact.firstName)
                        .id("\(contact.image ?? "")\(contact.id ?? 0)")
                        .font(.iransansBody)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading, 16)
                            .lineLimit(1)
                            .font(.iransansBody)
                        if let notSeenDuration = contact.notSeenString {
                            Text(notSeenDuration)
                                .padding(.leading, 16)
                                .font(.iransansCaption2)
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if contact.blocked == true {
                        Text("Blocked")
                            .font(.caption2.weight(.medium))
                            .padding(4)
                            .foregroundColor(.redSoft)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.redSoft)
                            )
                    }
                })
            }
        }
        .animation(.spring(), value: isInMultiSelectMode)
        .animation(.easeInOut, value: isSelected)
        .contentShape(Rectangle())
    }
}

struct StartThreadContactRow_Previews: PreviewProvider {
    @State static var isInMultiSelectMode = true
    static var previews: some View {
        Group {
            StartThreadContactRow(isInMultiSelectMode: $isInMultiSelectMode, contact: MockData.contact)
                .environmentObject(ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
