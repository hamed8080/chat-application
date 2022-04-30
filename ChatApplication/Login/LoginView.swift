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
                if viewModel.isLoading{
                    LoadingView()
                        .frame(width: 36, height: 36)
                }
                Spacer()
            }
            .padding()
            .padding()
        }
        .animation(.easeInOut, value: viewModel.model.isInVerifyState)
    }
}

struct VerifyContentView:View{
    
    @StateObject var viewModel:LoginViewModel
    
    var body: some View{
        VStack(alignment:.center, spacing:16){
            CustomNavigationBar(title:"Verification") {
                viewModel.model.setIsInVerifyState(false)
            }
            .padding([.bottom], 48)
            Image("global_app_icon")
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
            PrimaryTextField(title:"Enter Verification Code",textBinding: $viewModel.model.verifyCode){
                viewModel.verifyCode()
            }
            Button("Verify".uppercased()) {
                viewModel.verifyCode()
            }
            .buttonStyle(PrimaryButtonStyle())
            
            if viewModel.model.state == .VERIFICATION_CODE_INCORRECT{
                Text("Verification Code was incorrect!")
                    .foregroundColor(.red)
            }
        }
        .transition(.move(edge: .trailing))
        
    }
}

struct LoginContentView:View{
    @StateObject var viewModel:LoginViewModel
    
    var body: some View{
        VStack(alignment:.center,spacing: 16){
            Image("global_app_icon")
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
            
            PrimaryTextField(title:"Phone number",textBinding: $viewModel.model.phoneNumber){
            }
            
            if viewModel.model.isValidPhoneNumber == false{
                Text("Please input correct phone number")
                    .foregroundColor(.init("red_soft"))
            }
            
            Button("Login".uppercased()) {
                if viewModel.model.isPhoneNumberValid(){
                    viewModel.login()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Text("If you get in trouble with the login, contact the support team.")
                .multilineTextAlignment(.center)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(named: "text_color_blue").opacity(0.7))
        }
        .transition(.move(edge: .trailing))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = LoginViewModel()
        LoginView(viewModel: vm).preferredColorScheme(.light).onAppear{
            //            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            //                vm.model.setIsInVerifyState(true)
            //            }
            vm.model.setIsInVerifyState(false)
        }
    }
}

