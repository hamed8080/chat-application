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
    
    @State
    private var isSelected   = false
    
    @Binding
    public var isInEditMode:Bool
    
    public var viewModel:ContactsViewModel
    
    @EnvironmentObject
    var appState:AppState
    
    var body: some View {
        VStack{
            Button(action:{
                isSelected.toggle()
                viewModel.toggleSelectedContact(contact ,isSelected)
            }){
                HStack(spacing: 0, content: {
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
                            .padding(.leading , 16)
                            .lineLimit(1)
                            .font(.headline)
                        if let notSeenDuration = getDate(contact: contact){
                            Text(notSeenDuration)
                                .padding(.leading , 16)
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
                    if isInEditMode == false{
                        Button(action: {
                            
                            appState.isP2PCalling = true
                            appState.selectedContacts = [contact]
                            withAnimation(.spring()){
                                appState.showCallView.toggle()
                            }
                            
                        }, label: {
                            Image(systemName: "phone")
                                .resizable()
                                .frame(width: 24, height: 24)
                        })
                        .padding(16)
                    }
                    
                })
            }
        }.padding()
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
    @State static var isInEditMode = false
    static var contact:Contact{
        let contact = Contact(blocked: false, cellphoneNumber: "+98 9369161601", email: nil, firstName: "Hamed", hasUser: true, id: 0, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", lastName: "Hosseini", linkedUser: nil, notSeenDuration: 1622969881, timeStamp: nil, userId: nil)
        return contact
    }
    
    static var previews: some View {
        Group {
            ContactRow(contact: contact, isInEditMode: $isInEditMode,viewModel: ContactsViewModel())
        }
    }
}
