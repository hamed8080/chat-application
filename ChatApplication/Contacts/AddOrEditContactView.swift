//
//  AddOrEditContactView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/23/21.
//

import SwiftUI
import FanapPodChatSDK

struct AddOrEditContactView: View {
    
    @State var contactValue :String = ""
    @State var firstName    :String = ""
    @State var lastName     :String = ""
    @Environment(\.presentationMode) var presentationMode
    
    @State var title    :String  = "Contacts"
    
    var body: some View{
        GeometryReader{ reader in
            VStack(spacing:24){
                CustomNavigationBar(title:"Add contact",showDivider: false){
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.bottom , 24)
                PrimaryTextField(title:"type contact",textBinding: $contactValue,keyboardType: .alphabet)
                PrimaryTextField(title:"first name",textBinding: $firstName,keyboardType: .alphabet)
                PrimaryTextField(title:"last name",textBinding: $lastName, keyboardType: .alphabet)
                
                Button(action: {
                    let isPhone = validatePhone(value: contactValue)
                    let req:AddContactRequest = isPhone ?
                        .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, typeCode: nil, uniqueId: nil) :
                        .init(email:nil,firstName:firstName,lastName: lastName, ownerId: nil, username: contactValue, typeCode: nil, uniqueId: nil)
                    Chat.sharedInstance.addContact(req) { contacts, uniqueId, error in
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }, label: {
                    Text("Submit")
                })
                    .buttonStyle(PrimaryButtonStyle())
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .padding()
            .padding()
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .background(Color.gray.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
        )
        
    }
    
    func validatePhone(value: String) -> Bool {
        let PHONE_REGEX = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result = phoneTest.evaluate(with: value)
        return result
    }
}

struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddOrEditContactView()
    }
}
