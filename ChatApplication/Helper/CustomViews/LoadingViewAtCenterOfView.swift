//
//  LoadingViewAtCenterOfView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct LoadingViewAtCenterOfView: View {
    
    var isLoading:Bool
    @State private var isAnimatingLoadMore:Bool = false
    var reader:GeometryProxy
    
    var body: some View {
        if isLoading{
            LoadingView(isAnimating: $isAnimatingLoadMore,width: 2,color: .gray)
                .frame(width: 24, height: 24, alignment: .center)
                .offset(x: reader.size.width / 2 - (24 / 2), y: reader.size.height / 2 - (24 / 2))
                .onAppear{
                    isAnimatingLoadMore = true
                }
        }
    }
}
