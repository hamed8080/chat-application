//
//  StartThreadContactPickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct StartThreadResultModel{
    var selectedContacts :[Contact]? = nil
    
    var type             :ThreadTypes = .normal
    
    var title            :String = ""
}

struct StartThreadContactPickerView:View {
    
    @StateObject
    var viewModel:StartThreadContactPickerViewModel
    
    @StateObject
    var contactsVM = ContactsViewModel()
    
    @EnvironmentObject var appState:AppState
    
    @State var title    :String  = "New Message"
    @State var subtitle :String  = ""
    @State var isInMultiSelectMode = false
    
    var onCompletedConfigCreateThread:(StartThreadResultModel)->()
    
    @State
    var startThreadModel: StartThreadResultModel = .init()
    
    @State
    var showGroupTitleView:Bool = false
    
    @State var showEnterGroupNameError:Bool = false
    
    @State var groupTitle:String = ""
    
    var body: some View{
        
        VStack(alignment:.leading,spacing: 0){
            
            HStack{
                backButton()
                Spacer()
                nextButton()
            }
            .padding()
            
            if showGroupTitleView{
                VStack{
                    MultilineTextField("Enter group name", text: $groupTitle, backgroundColor:Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(showEnterGroupNameError ? Color.red : Color.clear, lineWidth: 1)
                        )
                    
                }
                .padding([.leading, .trailing,.top], 16)
                Spacer()
            }else{
                
                StartThreadButton(name: "bookmark.circle", title: "Save Message", color: .blue){
                    onCompletedConfigCreateThread(.init(selectedContacts: nil, type: .selfThread, title: ""))
                }
                
                StartThreadButton(name: "person.2", title: "New Group", color: .blue){
                    isInMultiSelectMode.toggle()
                    startThreadModel.type = .channelGroup
                }
                
                StartThreadButton(name: "megaphone", title: "New Channel", color: .blue){
                    isInMultiSelectMode.toggle()
                    startThreadModel.type = .channel
                }
                List {
                    ForEach(contactsVM.model.contacts , id:\.id) { contact in
                        
                        StartThreadContactRow(contact: contact, isInMultiSelectMode: $isInMultiSelectMode, viewModel: contactsVM)
                            .onTapGesture {
                                if isInMultiSelectMode == false{
                                    onCompletedConfigCreateThread(.init(selectedContacts: [contact], type: .normal, title: ""))
                                }
                            }
                            .onAppear {
                                if contactsVM.model.contacts.last == contact{
                                    contactsVM.loadMore()
                                }
                            }
                    }.onDelete(perform: { indexSet in
                        //                        guard let thread = indexSet.map({ viewModel.model.threads[$0]}).first else {return}
                        //                        viewModel.deleteThread(thread)
                    })
                }
                .listStyle(.plain)
            }
        }
        .padding(0)
    }
    
    @ViewBuilder
    func backButton()-> some View{
        if showGroupTitleView{
            Button {
                withAnimation {
                    showGroupTitleView = false
                }
            } label: {
                Text(showGroupTitleView == true ? "Back" : "")
            }
        }
    }
    
    @ViewBuilder
    func nextButton()->some View{
        if isInMultiSelectMode{
            Button {
                withAnimation {
                    if showGroupTitleView == true{
                        if groupTitle.isEmpty{
                            showEnterGroupNameError = true
                        }else{
                            onCompletedConfigCreateThread(.init(selectedContacts: contactsVM.model.selectedContacts, type: startThreadModel.type , title: groupTitle))
                        }
                    }else{
                        showGroupTitleView.toggle()
                    }
                }
            } label: {
                Text(showGroupTitleView == false ? "Next" :"Create")
            }
        }
    }
}

struct StartThreadButton:View{
    
    var name:String
    var title:String
    var color:Color
    var action: (()->Void)?
    
    @State var isActive = false
    
    var body: some View{
        Button {
            action?()
        } label: {
            HStack{
                Image(systemName: name)
                Text(title)
                Spacer()
            }
        }
        .padding()
        .foregroundColor(.blue)
    }
}


struct StartThreadContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = StartThreadContactPickerViewModel()
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView(viewModel: vm,contactsVM: contactVM, onCompletedConfigCreateThread: { model in
        })
        .preferredColorScheme(.dark)
        .onAppear(){
            vm.setupPreview()
            contactVM.setupPreview()
        }
        .environmentObject(appState)
    }
}
