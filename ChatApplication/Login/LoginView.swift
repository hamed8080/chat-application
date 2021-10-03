//
//  LoginView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var viewModel            :LoginViewModel
    
    var body: some View {
        VStack{
            Text(viewModel.model.state?.rawValue ?? "")
            if viewModel.model.isInVerifyState == false{
                LoginContentView(viewModel: viewModel)
            }else{
                VerifyContentView(viewModel: viewModel)
            }
        }
        .animation(.default)
        .padding(16)
    }
    
}

struct VerifyContentView:View{
    @StateObject var viewModel:LoginViewModel
    
    var body: some View{
        VStack(alignment:.trailing){
            HStack{
                Button("< Back") {
                    viewModel.model.setIsInVerifyState(false)
                }
                .font(.headline.bold())
                Spacer()
            }
            
            Spacer()
            
            TextFieldLogin(title:"Enter Verification Code",textBinding: $viewModel.model.verifyCode){
                 viewModel.verifyCode()
            }
            
            Button("Verify".uppercased()) {
                viewModel.verifyCode()
            }
            .buttonStyle(LoginButtonStyle())
            
            if viewModel.model.state == .VERIFICATION_CODE_INCORRECT{
                Text("Verification Code was incorrect!")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .transition(.move(edge: .trailing))

    }
}

struct LoginContentView:View{
    @StateObject var viewModel:LoginViewModel
    
    var body: some View{
        VStack(alignment:.trailing){
            TextFieldLogin(title:"Phone number",textBinding: $viewModel.model.phoneNumber){
                viewModel.model.isPhoneNumberValid()
            }
            
            Button("Login".uppercased()) {
                viewModel.login()
            }
            .buttonStyle(LoginButtonStyle())
            
            if viewModel.model.isValidPhoneNumber == false{
                Text("Please input correct phone number")
                    .foregroundColor(.red)
            }
        }
        .transition(.move(edge: .trailing))
    }
}

struct TextFieldLogin:View{
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
        .frame(minWidth: 100, minHeight: 48, alignment: .center)
        .keyboardType(keyboardType)
        .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.2), style: StrokeStyle(lineWidth:1)))
    }
}

struct LoginButtonStyle:ButtonStyle{
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 100, minHeight: 48, alignment: .center)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(16)
    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = LoginViewModel()
        LoginView(viewModel: vm).onAppear{
//            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
//                vm.model.setIsInVerifyState(true)
//            }
            vm.model.setIsInVerifyState(true)
        }
    }
}

