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
            let size:CGFloat = isIpad ? 48 : 36
            let bottom = reader.safeAreaInsets.bottom > 0 ? max(size, reader.safeAreaInsets.bottom ) : size
            LoadingView(width: 3)
                .frame(width: size, height: size, alignment: .center)
                .offset(x: reader.size.width / 2 - (size / 2), y: reader.size.height - bottom)
        }
    }
}
