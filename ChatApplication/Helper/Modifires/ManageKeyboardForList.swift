//
//  ManageKeyboardForList.swift
//  ChatApplication
//
//  Created by hamed on 3/13/22.
//

import SwiftUI

struct ManageKeyboardForList: ViewModifier {
    
    @Binding
    var isKeyboardShown:Bool
    
    @State
    var observer:Any? = nil
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                observer = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
                    isKeyboardShown = true
                }
            }
            .onTapGesture {
                if isKeyboardShown == true{
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)              
                }
            }
            .onDisappear {
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                    self.observer = nil
                }
            }
    }
}

extension View {
    
    func manageKeyboardForList(isKeyboardShown:Binding<Bool>) -> ModifiedContent<Self, ManageKeyboardForList> {
        return modifier(ManageKeyboardForList(isKeyboardShown: isKeyboardShown))
    }
}
