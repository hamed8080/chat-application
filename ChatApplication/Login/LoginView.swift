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
        ZStack{
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing:12){
                if viewModel.model.isInVerifyState == false{
                    LoginContentView(viewModel: viewModel)
                }else{
                    VerifyContentView(viewModel: viewModel)
                }
            }
            .padding()
            .padding()
        }
        .animation(.default)
    }
}

struct VerifyContentView:View{
    
    @StateObject var viewModel:LoginViewModel
    
    var body: some View{
        VStack(alignment:.center, spacing:16){
            HStack{
                Button {
                    viewModel.model.setIsInVerifyState(false)
                } label: {
                    Image(systemName: "chevron.backward.circle.fill")
                }
                .foregroundColor(Color(named: "text_color_blue").opacity(0.8))
                .font(.largeTitle.weight(.medium))
                Spacer()
            }
            .padding([.bottom], 48)
            Image(uiImage: UIImage.appIcon!)
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Enter Verication Code")
                .font(.title.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue"))
            
            Text("Verification code sent to:")
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
            + Text(" \(viewModel.model.phoneNumber)")
                .font(.subheadline.weight(.bold))
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
        VStack(alignment:.center,spacing: 16){
            Image(uiImage: UIImage.appIcon!)
                .resizable()
                .frame(width: 72, height: 72)
                .scaledToFit()
                .cornerRadius(8)
            Text("Login")
                .font(.title.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue"))
            Text("Welcome to Fanap Chats")
                .font(.headline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
            Text(viewModel.model.state?.rawValue ?? "")
            
            TextFieldLogin(title:"Phone number",textBinding: $viewModel.model.phoneNumber){
                viewModel.model.isPhoneNumberValid()
            }
            
            Button("Login".uppercased()) {
                viewModel.login()
            }
            .buttonStyle(LoginButtonStyle())
            
            Text("If you get in trouble with the login, contact the support team.")
                .multilineTextAlignment(.center)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
            Spacer()
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
        .frame(minHeight:56)
        .background(Color.white.cornerRadius(8))
    }
}

struct LoginButtonStyle:ButtonStyle{
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader{ reader in
            configuration.label
                .frame(minWidth: reader.size.width, minHeight: 56, alignment: .center)
                .foregroundColor(Color.white)
                .background(Color(named: "text_color_blue"))
                .cornerRadius(8)
                .font(.subheadline.weight(.black))
                .shadow(radius: 8)
        }.frame(maxHeight: 56, alignment: .center)
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

