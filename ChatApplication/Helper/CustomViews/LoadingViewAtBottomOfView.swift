//
//  LoadingViewAtBottomOfView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct LoadingViewAtBottomOfView: View {
    
    var isLoading:Bool
    var reader:GeometryProxy
    
    var body: some View {
        if isLoading{
            let bottom = reader.safeAreaInsets.bottom > 0 ? reader.safeAreaInsets.bottom : 24
            LoadingView(width: 3)
                .frame(width: isIpad ? 64 : 36, height: isIpad ? 64 : 36, alignment: .center)
                .offset(x: reader.size.width / 2 - (24 / 2), y: reader.size.height - bottom)
        }
    }
}
