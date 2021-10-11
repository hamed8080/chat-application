//
//  SettingsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct SettingsView:View {
    
    @State var showLogs:Bool    = false
    @StateObject var viewModel  = SettingViewModel()
    
    @EnvironmentObject
    var appState:AppState
        
    var body: some View{
            ScrollView{
                HStack(spacing:0){
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                
                            }, label: {
                                Image(systemName:"square.and.pencil")
                                    .font(.title)
                            })
                        }
                        .padding(.top)
                        .padding(.bottom , 25)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                            .frame(width: 128, height: 128)
                            .shadow(color: .black, radius: 20, x: 0, y: 0)
                            .overlay(
                                Avatar(url: viewModel.model.currentUser?.image,
                                       userName: viewModel.model.currentUser?.username?.uppercased() ?? "",
                                       size:128,
                                       textSize: 64
                                )
                            )
                        
                        
                        VStack(spacing:12){
                            Text(viewModel.model.currentUser?.name ?? "")
                                .font(.title.bold())
                            Text(viewModel.model.currentUser?.cellphoneNumber ?? "")
                                .font(.subheadline)
                        }
                        .padding(.top , 25)
                        
                        HStack{
                            Image(systemName:"moon.fill")
                                .font(.body)
                            Text("Dark Mode")
                                .font(.body)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    appState.dark.toggle()
                                    UIApplication.shared.windows.first?.rootViewController?.view.overrideUserInterfaceStyle = appState.dark ? .dark : .light
                                    UIApplication.shared.windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                                }
                            }, label: {
                                Image("on")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(appState.dark ? .white : .black)
                                    .frame(width: 48, height: 42, alignment: .center)
                                    .scaledToFit()
                                    .rotationEffect(.init(degrees: appState.dark ? 180 : 0))
                            })
                        }
                        .padding(.top , 25)
                        
                        Group{
                            GroupItemInSlideMenu(name: "gear", title: "Setting", color: .blue,destinationView:EmptyView())
                            Divider()
                            GroupItemInSlideMenu<EmptyView>(name: "phone", title: "Calls", color: .green,destinationView:EmptyView())
                            GroupItemInSlideMenu<EmptyView>(name: "bookmark", title: "Saved Messages", color: Color.purple , destinationView:EmptyView())
                            GroupItemInSlideMenu<ResultView>(name: "note.text", title: "Logs", color: Color.yellow , destinationView:ResultView())
                            
                            Button(action: {
                                Chat.sharedInstance.newlogOut()
                                CacheFactory.write(cacheType: .DELETE_ALL_CACHE_DATA)
                                TokenManager.shared.clearToken()
                            }, label: {
                                HStack{
                                    Image(systemName:"arrow.backward.circle")
                                        .font(.body)
                                        .foregroundColor(.red)
                                    Text("Logout")
                                    Spacer()
                                }.padding([.top , .bottom] , 12)
                            })
                            #if DEBUG
                            HStack{
                                Image(systemName: "key.fill")
                                    .foregroundColor(Color.yellow)
                                    .frame(width: 24, height: 24)
                                Text("Token expire in: \(viewModel.secondToExpire)")
                                    .foregroundColor(Color.gray)
                                Spacer()
                            }
                            #endif
                        }
                        Spacer()
                        NavigationLink(destination: ResultView(),isActive: $showLogs){}.hidden()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal , 36)
                }
            }
            .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
        .onAppear{
            viewModel.startTokenTimer()
        }
    }
}

struct GroupItemInSlideMenu<DestinationView:View>:View {
    
    var name:String
    var title:String
    var color:Color
    var destinationView:DestinationView? = nil
    var action: (()->Void)?
    
    @State var isActive = false
    
    var body: some View{
        NavigationLink(destination: destinationView,isActive: $isActive){
            
            Button(action: {
                isActive.toggle()
                action?()
            }, label: {
                HStack{
                    Image(systemName:name)
                        .font(.body)
                        .foregroundColor(color)
                    Text(title)
                        .font(.body)
                    Spacer()
                }.padding([.top , .bottom] , 12)
            })
        }
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark:Bool = false
    @State static var show:Bool = false
    @State static var showBlackView:Bool = false
    @State static var viewModel = SettingViewModel()
    
    static var previews: some View {
        Group {
            SettingsView(viewModel:viewModel)
                .environmentObject(AppState.shared)
                .onAppear{
                    viewModel.model.setCurrentUser(User(cellphoneNumber: "+98 936 916 1601", contactSynced: nil, coreUserId: nil, email: "h.hosseini.co@gmail.com", id: nil, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", lastSeen: nil, name: "Hamed Hosseini", receiveEnable: nil, sendEnable: nil, username: "hamed8080", chatProfileVO: nil))
                }
        }
    }
}
