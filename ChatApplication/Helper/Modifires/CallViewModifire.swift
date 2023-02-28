//
//  CallViewModifire.swift
//  ChatApplication
//
//  Created by hamed on 3/15/22.
//

import FanapPodChatSDK
import SwiftUI

struct CallViewModifire: ViewModifier {
    @Binding var isShowing: Bool
    var duration: TimeInterval = 15

    func body(content: Content) -> some View {
        ZStack {
            content
                .animation(.easeInOut, value: isShowing)
                .blur(radius: isShowing ? 5 : 0)
            if isShowing {
                VStack {
                    CallViewModifireContent()
                        .background(.ultraThickMaterial)
                        .cornerRadius(24, corners: [.bottomRight, .bottomLeft])
                    Spacer()
                }
                .background(.clear)
                .transition(.move(edge: .top))
            }
        }
        .ignoresSafeArea()
        .onChange(of: isShowing) { newValue in
            if newValue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
        .animation(.spring(response: isShowing ? 0.5 : 2, dampingFraction: isShowing ? 0.85 : 1, blendDuration: 1), value: isShowing)
    }
}

struct CallViewModifireContent: View {
    var body: some View {
        StartCallActionsView()
            .padding(.bottom)
            .frame(width: 320, height: 148)
    }
}

extension View {
    func call(isShowing: Binding<Bool>, duration: TimeInterval = 3) -> some View {
        modifier(CallViewModifire(isShowing: isShowing, duration: duration))
    }
}

struct TestCallViewModifire: View {
    @State var isShowing = false

    var body: some View {
        Text("hello")
            .call(isShowing: $isShowing)
            .onTapGesture {
                withAnimation {
                    isShowing = true
                }
            }
    }
}

struct TopCallViewModifire_Previews: PreviewProvider {
    @ObservedObject static var viewModel = CallViewModel.shared
    static var previews: some View {
        TestCallViewModifire()
            .environmentObject(viewModel)
            .previewDevice("iPhone 13 Pro Max")
    }
}
