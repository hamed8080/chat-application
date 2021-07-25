//
//  SettingsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct SettingsView:View {
    
    @State var showLogs:Bool = false
    
    @EnvironmentObject
    var appSatate:AppState
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
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
                                Image("avatar")
                                    .resizable()
                                    .padding()
                            )
                        
                        
                        VStack(spacing:12){
                            Text("Hamed Hosseini")
                                .font(.title.bold())
                            Text("+98 936 916 16 01")
                                .font(.subheadline)
                        }
                        .padding(.top , 25)
                        
                        HStack{
                            Image(systemName:"moon.fill")
                                .font(.title2)
                            Text("Dark Mode")
                                .font(.title2)
                            
                            Spacer()
                            
                            Button(action: {
                                appSatate.dark.toggle()
                                UIApplication.shared.windows.first?.rootViewController?.view.overrideUserInterfaceStyle = appSatate.dark ? .dark : .light
                                UIApplication.shared.windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                            }, label: {
                                Image("on")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(appSatate.dark ? .white : .black)
                                    .frame(width: 48, height: 42, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                    .scaledToFit()
                                    .rotationEffect(.init(degrees: appSatate.dark ? 180 : 0))
                            })
                        }
                        .padding(.top , 25)
                        
                        Group{
                            GroupItemInSlideMenu(name: "gear", title: "Setting", color: .blue,destinationView:EmptyView())
                            Divider()
                            GroupItemInSlideMenu<EmptyView>(name: "phone", title: "Calls", color: .green,destinationView:EmptyView())
                            GroupItemInSlideMenu<EmptyView>(name: "bookmark", title: "Saved Messages", color: Color.purple , destinationView:EmptyView())
                            GroupItemInSlideMenu<ResultView>(name: "note.text", title: "Logs", color: Color.yellow , destinationView:ResultView())
                            GroupItemInSlideMenu<EmptyView>(name: "trash.fill", title: "Clear Cache Data", color: Color.red , destinationView:EmptyView()){
                                CacheFactory.write(cacheType: .DELETE_ALL_CACHE_DATA)
                            }
                        }
                        Spacer()
                        NavigationLink(destination: ResultView(),isActive: $showLogs){}.hidden()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal , 36)
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
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
                        .font(.title2)
                        .foregroundColor(color)
                    Text(title)
                        .font(.title2)
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
    
    static var previews: some View {
        SettingsView()
    }
}
