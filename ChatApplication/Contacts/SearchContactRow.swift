//
//  SearchContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/16/21.
//

import SwiftUI
import FanapPodChatSDK

struct SearchContactRow: View {
    
    var contact:Contact
    
    public var viewModel:ContactsViewModel
    
    var body: some View{
        HStack{
            Avatar(url:contact.image ?? contact.linkedUser?.image ,userName: contact.firstName?.uppercased(), fileMetaData: nil, style: .init(size: 24, textSize: 12))
            VStack(alignment: .leading, spacing:4){
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading , 4)
                    .lineLimit(1)
                    .font(.headline)
                if let notSeenDuration = ContactRow.getDate(notSeenDuration: contact.notSeenDuration){
                    Text(notSeenDuration)
                        .padding(.leading , 4)
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color.gray)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: .infinity, height: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)])
        }
    }
}

struct SearchContactRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchContactRow(contact: ContactRow_Previews.contact,viewModel: ContactsViewModel())
    }
}
