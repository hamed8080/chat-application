//
//  LoadingViewAt.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

enum LoadingViewPosition{
    case TOP
    case CENTER
    case BOTTOM
}
struct LoadingViewAt: View {
    
    var at:LoadingViewPosition = .BOTTOM
    var isLoading:Bool
    var reader:GeometryProxy
    var size:CGFloat{
        return isIpad ? 36 : 28
    }
    
    var body: some View {
        if isLoading{
            LoadingView(width: 3)
                .frame(width: size, height: size, alignment: .center)
                .offset(x: reader.size.width / 2 - (size / 2), y: reader.size.height - position(reader: reader))
        }
    }
    
    func position(reader:GeometryProxy) -> CGFloat{
        switch at {
        case .TOP:
            return 0
        case .CENTER:
            return reader.size.height / 2
        case .BOTTOM:
            return reader.safeAreaInsets.bottom > 0 ? max(size, reader.safeAreaInsets.bottom ) : size
        }
    }
}
