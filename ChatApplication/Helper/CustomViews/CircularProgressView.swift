//
//  CircularProgressView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/27/21.
//

import SwiftUI

struct CircularProgressView: View {
    @Binding var percent: Int64

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .foregroundColor(Color.gray.opacity(0.5))

            Text("\(percent) %")
                .font(.title2)
                .foregroundColor(.indigo)
                .fontWeight(.heavy)

            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.indigo)
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
