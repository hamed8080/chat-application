//
//  ViewExtension.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/28/21.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    var isIpad:Bool{
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
}
