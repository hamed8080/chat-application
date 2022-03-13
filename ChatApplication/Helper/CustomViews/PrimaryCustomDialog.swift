//
//  PrimaryCustomDialog.swift
//  ChatApplication
//
//  Created by Hamed on 1/15/22.
//

import SwiftUI

struct PrimaryCustomDialog: View {
    
    var title           :String
    var message         :String?           = nil
    var systemImageName :String?           = nil
    var textBinding     :Binding<String>?  = nil
    @Binding
    var hideDialog      :Bool
    var textPlaceholder :String?           = nil
    var submitTitle     :String            = "Submit"
    var cancelTitle     :String            = "Cancel"
    var onSubmit        :((String)->())?   = nil
    var onClose         :(()->())?         = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        VStack(spacing:2){
            if let systemImageName = systemImageName {
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth:72)
                    .padding()
                    .foregroundColor(colorScheme == .dark ? Color.gray : Color.gray )
            }
            
            Text(title)
                .fontWeight(.bold)
                .padding([.top,.bottom])
            if let message = message {
                Text(message)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color.gray)
                    .padding([.bottom])
            }
            if let textBinding = textBinding {
                PrimaryTextField(title: textPlaceholder ?? "",
                                 textBinding: textBinding,
                                 isEditing: true,
                                 keyboardType: .alphabet,
                                 backgroundColor: .black.opacity(0.05)
                ){
                    
                }
                .padding([.top,.bottom])
                .padding(.bottom)
            }
            
            Button(submitTitle){
                onSubmit?(textBinding?.wrappedValue ?? "")
                hideDialog.toggle()
            }.buttonStyle(PrimaryButtonStyle(bgColor:Color.pink.opacity(colorScheme == .dark ? 0.9 : 0.25),
                                             textColor: Color.primary.opacity(0.8),
                                             minHeight: 48,
                                             cornerRadius: 12))
            
            Button(cancelTitle){
                withAnimation {
                    hideDialog.toggle()
                    onClose?()
                }
            }.buttonStyle(PrimaryButtonStyle(bgColor:colorScheme == .dark ? Color.primary.opacity(0.3) : Color.black.opacity(0.1),
                                             textColor: colorScheme == .dark ? Color.white : Color.black.opacity(0.5),
                                             minHeight:48,
                                             cornerRadius: 12))
        }
    }
}

struct PrimaryCustomDialog_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryCustomDialog(title: "Title",
                            message: "Message",
                            systemImageName: "trash.fill",
                            textBinding: .constant("Text"),
                            hideDialog: .constant(false))
            .preferredColorScheme(.dark)
    }
}
