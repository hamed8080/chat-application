//
//  RecordAudioBackground.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/1/21.
//

import SwiftUI

struct RecordAudioBackground: View {
    
    @StateObject var viewModel:ThreadViewModel
    
    @State
    var degrees:[CGFloat] = [270,40,70,90,120,160,220,260,290,360]
    var scale:CGFloat = 6
    var cornerRadius:CGFloat = 24
    var blurRadius = 1
    
    var body: some View {
        if viewModel.model.isRecording {
            ZStack{
                ForEach(1...10, id:\.self){ item in
                    createRectangle(index: item - 1)
                }
            }
            .customAnimation(
                    .easeInOut(duration: 0.5)
                    .speed(0.099)
                    .repeatForever(autoreverses: true)
                    .delay(0.0)
            )
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                    degrees.enumerated().forEach { element in
                        degrees[element.offset] = element.element + (element.element * 80 / 100)
                    }
                }
            }
        }
        else{
            Circle()
                .scale()
                .foregroundColor(Color.clear)
        }
    }
    
    @ViewBuilder
    func createRectangle(index:Int)->some View{
        RoundedRectangle(cornerRadius: cornerRadius)
            .scale(x: scale, y: scale)
            .rotation(Angle(degrees: degrees[index]))
            .foregroundColor(Color(named: "text_color_blue").opacity((Double(index) * 80/100)))
            .blur(radius: CGFloat(index) * 80/100 )
    }
}

struct RecordAudioBackground_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel(thread: ThreadRow_Previews.thread)
        RecordAudioBackground(viewModel: vm, scale: 2)
            .frame(width: 128, height: 128)
            .onAppear {
                vm.toggleRecording()
            }
    }
}
