//
//  Message.swift
//  ChatApplication
//
//  Created by hamed on 4/15/22.
//

import Foundation
import FanapPodChatSDK
import SwiftUI

extension Message{
    
    func calculatedMaxAndMinWidth(proxy:GeometryProxy)->(minWidth:CGFloat,maxWidth:CGFloat){
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let maxViewWidth = isIpad ? proxy.size.width * (40 / 100) : UIScreen.main.bounds.width
        let actualWidth = CGFloat( metaData?.file?.actualWidth ?? 0)
        let textWidth = (message?.widthOfString(usingFont:UIFont.systemFont(ofSize: 22)) ?? 0 ) + 16
        let maxImageAndText = max(textWidth, actualWidth)
        let maxWidth = min(maxViewWidth, max(128,maxImageAndText))
        let minWidth = min(128, maxWidth)
        return(minWidth,maxWidth)
    }
}
