//
//  ContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactRow: View {
    
    private (set) var contact:Contact
    @State private var isSelected   = false
    @Binding var isInEditMode:Bool
    var viewModel:ContactsViewModel
    
    var body: some View {
        Button(action:{
            isSelected.toggle()
            viewModel.toggleSelectedContact(contact ,isSelected)
        }){
            HStack(alignment: .center, spacing: 16, content: {
                if isInEditMode{
                    Image(systemName: isSelected ? "checkmark.circle" : "circle")
                        .font(.title)
                        .frame(width: 22, height: 22, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .foregroundColor(Color.blue)
                        .padding(24)
                }
                Avatar(url:contact.image ,userName: contact.firstName, fileMetaData: nil)
                VStack(alignment: .leading, spacing:8){
                    Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        .font(.headline)
                    if let notSeenDuration = getDate(contact: contact){
                        Text(notSeenDuration)
                            .font(.headline.weight(.medium))
                            .foregroundColor(Color.gray)
                    }
                }
                Spacer()
                if contact.blocked  == true{
                    Text("Blocked")
                        .font(.headline.weight(.medium))
                        .padding(4)
                        .foregroundColor(Color.red)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.red)
                        )
                }
            })
        }
        
    }
    
    func getDate(contact:Contact) -> String?{
        if let notSeenDuration = contact.notSeenDuration{
            let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(notSeenDuration)
            return Date(milliseconds:milisecondIntervalDate).timeAgoSinceDate()
        }else{
            return nil
        }
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInEditMode = true
    static var contact:Contact{
        let contact = Contact(blocked: false, cellphoneNumber: "+98 9369161601", email: nil, firstName: "Hamed", hasUser: true, id: 0, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", lastName: "Hosseini", linkedUser: nil, notSeenDuration: 1622969881, timeStamp: nil, userId: nil)
        return contact
    }
    
    static var previews: some View {
        
        ContactRow(contact: contact, isInEditMode: $isInEditMode,viewModel: ContactsViewModel())
    }
}
