//
//  LoadingViewAtCenterOfView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct LoadingViewAtCenterOfView: View {
    
    var isLoading:Bool
    var reader:GeometryProxy
    
    var body: some View {
        if isLoading{
            LoadingView(width: 2,color: .gray)
                .frame(width: isIpad ? 128 : 64, height: isIpad ? 128 : 64, alignment: .center)
                .offset(x: reader.size.width / 2 - (24 / 2), y: reader.size.height / 2 - (24 / 2))
        }
    }
}
