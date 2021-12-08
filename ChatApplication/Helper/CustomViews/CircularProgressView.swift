//
//  CircularProgressView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/27/21.
//

import SwiftUI

struct CircularProgressView: View {
    
    @Binding
    var percent:Double
    
    var body: some View{
        ZStack{
            Circle()
                .stroke(lineWidth: 4)
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text(String(format: "%.0f", percent) + " %")
                .foregroundColor(Color.white)
                .font(.title2)
                .fontWeight(.heavy)
            
            Circle()
                .trim(from: 0.0, to: min((percent / 100), 1.0) )
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.white)
                .rotationEffect(Angle(degrees: 270))
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressView(percent: .constant(60))
            .background(Color.black)
    }
}
