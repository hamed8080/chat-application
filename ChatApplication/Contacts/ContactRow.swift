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
    
    @State
    public var showActionViews:Bool = false
    
    @EnvironmentObject
    var callState:CallState
    
    var body: some View {
        VStack{
            VStack{
                HStack(spacing: 0, content: {
                    if isInEditMode{
                        Image(systemName: isSelected ? "checkmark.circle" : "circle")
                            .font(.title)
                            .frame(width: 22, height: 22, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(24)
                            .onTapGesture {
                                isSelected.toggle()
                                viewModel.toggleSelectedContact(contact ,isSelected)
                            }
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
                })
                .onTapGesture {
                    withAnimation {
                        showActionViews.toggle()
                    }
                }
                
                if showActionViews{
                    getActionsView()
                }else{
                    EmptyView()
                }
            }
            .padding(16)
            .animation(.default)
            .background(Color.black.opacity(0.05))
            .cornerRadius(16)
            
        }.padding()
    }
    
    
    @ViewBuilder
    func getActionsView()->some View{
        Divider()
        HStack(spacing:48){
            
            ActionButton(iconSfSymbolName: "message",taped:{
                viewModel.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)])
            })
            
            ActionButton(iconSfSymbolName: "video",height: 16,taped:{
                callState.model.setIsVideoCallRequest(true)
                callState.model.setIsP2PCalling(true)
                callState.model.setSelectedContacts([contact])
                withAnimation(.spring()){
                    callState.model.setShowCallView(true)
                }
            })
            
            ActionButton(iconSfSymbolName: "phone", taped:{
                callState.model.setIsP2PCalling(true)
                callState.model.setSelectedContacts([contact])
                withAnimation(.spring()){
                    callState.model.setShowCallView(true)
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


struct ActionButton: View{
    
    var iconSfSymbolName :String
    var height           :CGFloat      = 22
    var taped            :(()->Void)?
    
    var body: some View{
        Button(action: {
            taped?()
        }, label: {
            Image(systemName: iconSfSymbolName)
                .resizable()
                .frame(width: 24, height: height)
                .foregroundColor(.blue)
        })
        .buttonStyle(BorderlessButtonStyle())//don't remove this line click happen in all veiws
        .padding(16)
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
