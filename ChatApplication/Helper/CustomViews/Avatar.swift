//
//  Avatar.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
struct Avatar :View{
    
    @ObservedObject
    var imageLoader:ImageLoader
    
    @State var image:UIImage = UIImage()
    
    private (set) var url:String?
    private (set) var userName:String?
    
    init(url:String?, userName:String?) {
        self.url = url
        self.userName = userName
        imageLoader = ImageLoader(url: url)
    }
    
    var body: some View{
        HStack{
            if url != nil{
                Image(uiImage:imageLoader.image ?? self.image)
                    .resizable()
                    .frame(width: 64, height: 64, alignment: .center)
                    .cornerRadius(32)
                    .scaledToFit()
            }else{
                Text(String(userName?.first ?? "A" ))
                    .fontWeight(.heavy)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64, alignment: .center)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(32)
            }
        }
        .onReceive(imageLoader.didChange) { image in
            self.image = image ?? UIImage()
        }
    }
}


struct Acatar_Previews: PreviewProvider {
    
    static var previews: some View {
        Avatar(url: nil, userName: "Hamed Hosseini")
    }
}

