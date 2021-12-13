//
//  ViewEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/12/21.
//

import SwiftUI
extension View{
    
    @ViewBuilder
    func compatibleConfirmationDialog(_ isPresented:Binding<Bool>,message:String? = nil,title:String? = nil, _ buttons:[DialogButton])-> some View{
        if #available(iOS 15, *){
            self.confirmationDialog(title ?? "", isPresented: isPresented,titleVisibility: (title?.isEmpty ?? false) ? .hidden : .visible) {
                ForEach(buttons, id:\.self){ button in
                    Button {
                        withAnimation {
                            button.action()
                        }
                    } label: {
                        Text(button.title)
                    }
                }
            }
        }else{
            self.actionSheet(isPresented: isPresented) {
                let alertButtons = buttons.map({ Alert.Button.default(Text($0.title), action: $0.action)})
                return ActionSheet(title: Text(title ?? ""), message: Text(message ?? ""), buttons: alertButtons)
            }
        }
    }
}

struct DialogButton:Hashable{
    
    static func == (lhs: DialogButton, rhs: DialogButton) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    var title:String
    var action:()->()
    var id = UUID().uuidString
}
