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
            PageWithNavigationBarView(title:$title,showbackButton:true){
                VStack{
                    TextFieldLogin(title:"type contact",textBinding: $contactValue,keyboardType: .alphabet)
                    TextFieldLogin(title:"first name",textBinding: $firstName,keyboardType: .alphabet)
                    TextFieldLogin(title:"last name",textBinding: $lastName, keyboardType: .alphabet)
                    
                    Button(action: {
                        let isPhone = validatePhone(value: contactValue)
                        let req:NewAddContactRequest = isPhone ?
                            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, typeCode: nil, uniqueId: nil) :
                            .init(email:nil,firstName:firstName,lastName: lastName, ownerId: nil, username: contactValue, typeCode: nil, uniqueId: nil)
                        Chat.sharedInstance.addContact(req) { contacts, uniqueId, error in
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Text("Submit")
                    })
                    .buttonStyle(LoginButtonStyle())
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .padding(16)
            }
        }
        
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
