//
//  SelectedContact.swift
//  Talk
//
//  Created by hamed on 11/6/23.
//

import SwiftUI
import ChatModels
import TalkViewModels
import TalkUI

struct SelectedContact: View {
    let viewModel: ContactsViewModel
    let contact: Contact
    @State var isSelectedToDelete: Bool = false

    var body: some View {
        HStack {
            removeButton
            userImage
            userName
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(isSelectedToDelete ?  Color.App.primary : Color.App.gray8)
        .clipShape(RoundedRectangle(cornerRadius:(12)))
        .animation(.easeInOut, value: isSelectedToDelete)
        .onTapGesture {
            isSelectedToDelete.toggle()
        }
    }

    @ViewBuilder var removeButton: some View {
        if isSelectedToDelete {
            Button {
                viewModel.toggleSelectedContact(contact: contact)
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Color.App.white)
                    .contentShape(Rectangle())
            }
        }
    }

   @ViewBuilder var userImage: some View {
        if !isSelectedToDelete {
            let config = ImageLoaderConfig(url: contact.image ?? contact.user?.image ?? "", userName: contact.firstName)
            ImageLoaderView(imageLoader: .init(config: config), textFont: .iransansBoldCaption2)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .foregroundColor(Color.App.text)
                .frame(width: 18, height: 18)
                .background(Color.App.blue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(12)))
        }
    }

    var userName: some View {
        Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
            .lineLimit(1)
            .font(.iransansCaption2)
            .foregroundColor(isSelectedToDelete ? Color.App.white : Color.App.text)
    }
}

struct SelectedContact_Previews: PreviewProvider {
    static var previews: some View {
        SelectedContact(viewModel: .init(), contact: .init(firstName: "John", id: 1, lastName: "Doe"))
    }
}
