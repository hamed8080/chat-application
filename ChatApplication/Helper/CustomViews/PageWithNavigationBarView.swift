//
//  PageWithNavigationBarView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/22/21.
//

import SwiftUI

struct NavBarItem{
    let id = UUID()
    let view:AnyView
}

struct NavBarButton{
    var title:String? = nil
    var systemImageName:String? = nil
    var showAvatarImage = false
    var avatarUrl:String? = nil
    var avatarUserName:String? = nil
    var avatarMetaData:String? = nil
    var isBold:Bool = false
    var action:()->()
    
    func getNavBarItem() -> NavBarItem{
        
        return  NavBarItem(view: AnyView(
            Button(action: {
                action()
            }, label: {
                HStack{
                    if let systemImageName = systemImageName{
                        Image(systemName: systemImageName)
                    }
                    
                    if title == nil && showAvatarImage == true{
                        Avatar(url: avatarUrl, userName: avatarUserName?.uppercased() ,fileMetaData:avatarMetaData, style: .init(size: 32 ,textSize: 16))
                    }else if let title = title {
                        Text(title)
                            .fontWeight(isBold ? .bold : .medium)
                    }
                }
            })
        ))
    }
}

struct PageWithNavigationBarView<Content:View>: View {
    
    var title          :Binding<String>?
    var subtitle       :Binding<String>?
    
    var trailingItems  :[NavBarItem] = []
    var leadingItems   :[NavBarItem] = []
    var background     :Color        = .primary.opacity(0.08)
    var showbackButton :Bool         = false
    @Environment(\.presentationMode) var presentationMode
    
    
    var contentView:Content
    
    
    init(title                :Binding<String>?  = nil,
         subtitle             :Binding<String>?  = nil,
         trailingItems        :[NavBarItem]      = [],
         leadingItems         :[NavBarItem]      = [],
         showbackButton       :Bool              = false,
         @ViewBuilder content : @escaping () -> Content) {
        
        self.title          = title
        self.subtitle       = subtitle
        self.trailingItems  = trailingItems
        self.leadingItems   = leadingItems
        self.showbackButton = showbackButton
        self.contentView    = content()
    }
    
    var body: some View {
        GeometryReader{ reader in
            VStack(spacing:0){
                HStack(spacing:0){
                    
                    HStack{
                        if showbackButton{
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                HStack(spacing:0){
                                    Image(systemName: "chevron.backward")
                                    Text("Back")
                                }
                            })
                        }else{
                            ForEach(leadingItems, id: \.id){ item in
                                item.view
                            }
                        }
                    }
                    .frame(width: (reader.size.width / 6) * 1.5 )
                    
                    
                    VStack(spacing:2){
                        Text(title?.wrappedValue ?? "")
                            .bold()
                            .font(.headline)
                        if let subtitle = subtitle ,subtitle.wrappedValue != ""{
                            Text(subtitle.wrappedValue)
                                .bold()
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: (reader.size.width / 6) * 3 )
                    
                    
                    HStack{
                        ForEach(trailingItems, id: \.id){ item in
                            item.view
                        }
                    }
                    .frame(width: (reader.size.width / 6) * 1.5 )
                }
                .padding([.leading , .trailing], 8)
                .frame(width: reader.size.width,height: reader.navBarHeight)
                .background(     background
                                    .ignoresSafeArea(.all)
                )
                
                //shadow
                VStack{
                    
                }.frame(width: reader.size.width, height: 0.4)
                .background(Color(.separator))
                
                contentView
            }
            .navigationBarTitle("") //this must be empty
            .navigationBarHidden(true)
        }
    }
}

struct PageWithNavigationBarView_Previews: PreviewProvider {
    
    @State static var title:String = "Test Hamed"
    @State static var subtitle:String = "Test Hamed"
    
    static var previews: some View {
        
        PageWithNavigationBarView(title: $title,
                                  subtitle: nil ,
                                  trailingItems: [.init(view: AnyView(Button("trailing"){}))],
                                  leadingItems: [.init(view: AnyView(Button("leading"){}))],
                                  showbackButton: true
        ){
            Text("Hello")
        }
        .preferredColorScheme(.dark)
    }
}

extension GeometryProxy{
    
    var navBarHeight:CGFloat{
        let top = safeAreaInsets.top
        let height = top < 52 ? 52 : top
        return height
    }
}
