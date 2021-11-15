//
//  StringEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/10/21.
//

import Foundation
extension String{
    
    func isTypingAnimationWithText(onStart:@escaping (String)->(),onChangeText:@escaping (String)->(),onEnd:@escaping ()->()){
        onStart(self)
        var count = 0
        var indicatorCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if count >= 40 {
                onEnd()
                timer.invalidate()
            }else{
                if indicatorCount == 3{
                    indicatorCount = 0
                }else{
                    indicatorCount = indicatorCount + 1
                }
                onChangeText("typing" + String(repeating: "•", count: indicatorCount))
                count = count + 1
            }
        }
    }
}
