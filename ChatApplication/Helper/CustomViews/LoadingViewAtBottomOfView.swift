//
//  LoadingViewAtBottomOfView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct LoadingViewAtBottomOfView: View {
    
    var isLoading:Bool
    @State private var isAnimatingLoadMore:Bool = false
    var reader:GeometryProxy
    
    var body: some View {
        if isLoading{
            let bottom = reader.safeAreaInsets.bottom > 0 ? reader.safeAreaInsets.bottom : 24
            LoadingView(isAnimating: $isAnimatingLoadMore,width: 2)
                .frame(width: 24, height: 24, alignment: .center)
                .offset(x: reader.size.width / 2 - (24 / 2), y: reader.size.height - bottom)
                .onAppear{
                    isAnimatingLoadMore = true
                }
        }
    }
}
