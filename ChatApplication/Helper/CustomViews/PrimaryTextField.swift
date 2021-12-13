//
//  PrimaryTextField.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI

struct PrimaryTextField:View{
    var title                     :String
    @Binding var textBinding        :String
    @State var isEditing          :Bool         = false
    var onCommit                  :(()->())?    = nil
    var keyboardType:UIKeyboardType = .phonePad
    
    var body: some View{
        TextField(
            title,
            text: $textBinding
        ) { isEditing in
            self.isEditing = isEditing
        } onCommit: {
            onCommit?()
        }
        .keyboardType(keyboardType)
        .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 0))
        .frame(minHeight:56)
        .background(Color.white.cornerRadius(8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke( isEditing ? Color.gray : Color.clear))
        .animation(.easeInOut)
    }
}

struct PrimaryTextField_Previews: PreviewProvider {
    @State
    static var text:String = ""
    
    static var previews: some View {
        VStack{
            PrimaryTextField(title: "Placeholder", textBinding: $text)
            PrimaryTextField(title: "Placeholder", textBinding: $text)
        }
    }
}
