//
//  Avatar.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
struct Avatar :View{
    
    @ObservedObject
    var imageLoader                  :ImageLoader
    
    @State
    var image                        :UIImage = UIImage()
    
    private (set) var url            :String?
    private (set) var userName       :String?
    private (set) var size           :CGFloat
    private (set) var textSize        :CGFloat
    
    init(url          :String?,
         userName     :String?,
         fileMetaData :String? = nil,
         size         :CGFloat = 64,
         textSize     :CGFloat = 24
    ) {
        self.url      = url
        self.userName = userName
        self.size     = size
        self.textSize = textSize
        imageLoader = ImageLoader(url: url , fileMetaData:fileMetaData)
    }
    
    var body: some View{
        HStack(alignment:.center){
            if url != nil{
                Image(uiImage:imageLoader.image ?? self.image)
                    .resizable()
                    .frame(width: size, height: size)
                    .cornerRadius(size / 2)
                    .scaledToFit()
            }else{
                Text(String(userName?.first ?? "A" ))
                    .fontWeight(.heavy)
                    .font(.system(size: textSize))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(size / 2)
            }
        }
        .onReceive(imageLoader.didChange) { image in
            self.image = image ?? UIImage()
        }
    }
}


struct Acatar_Previews: PreviewProvider {
    
    static var previews: some View {
        Avatar(url: nil, userName: "Hamed Hosseini" , fileMetaData:nil)
    }
}

