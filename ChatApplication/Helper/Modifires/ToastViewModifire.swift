//
//  ToastViewModifire.swift
//  ChatApplication
//
//  Created by hamed on 3/15/22.
//

import SwiftUI

struct TopNotifyViewModifire<ContentView: View>: ViewModifier {
    @Binding private var isShowing: Bool
    let title: String?
    let message: String
    let duration: TimeInterval
    let backgroundColor: Color
    let leadingView: () -> ContentView

    internal init(isShowing: Binding<Bool>,
                  title: String? = nil,
                  message: String,
                  duration: TimeInterval,
                  backgroundColor: Color,
                  @ViewBuilder leadingView: @escaping () -> ContentView)
    {
        _isShowing = isShowing
        self.title = title
        self.message = message
        self.duration = duration
        self.leadingView = leadingView
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .animation(.easeInOut, value: isShowing)
                .blur(radius: isShowing ? 5 : 0)
            if isShowing {
                VStack {
                    toast
                        .ignoresSafeArea()
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

    private var toast: some View {
        VStack(spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.title2.bold())
            }
            HStack(spacing: 0) {
                leadingView()
                Text(message)
                    .font(.subheadline)
                    .padding()
                Spacer()
            }
        }
        .padding()
    }
}

extension View {
    func toast<ContentView: View>(isShowing: Binding<Bool>,
                                  title: String? = nil,
                                  message: String,
                                  duration: TimeInterval = 3,
                                  backgroundColor: Color = .bgColor,
                                  @ViewBuilder leadingView: @escaping () -> ContentView) -> some View
    {
        modifier(
            TopNotifyViewModifire(
                isShowing: isShowing,
                title: title,
                message: message,
                duration: duration,
                backgroundColor: backgroundColor,
                leadingView: leadingView
            )
        )
    }
}

struct TestView: View {
    @State var isShowing = false

    var body: some View {
        Text("hello")
            .toast(isShowing: $isShowing, title: "Test Title", message: "Test message") {
                Image(uiImage: UIImage(named: "avatar.png")!)
            }
            .onTapGesture {
                isShowing = true
            }
    }
}

struct TopNotifyViewModifire_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
            .previewDevice("iPhone 13 Pro Max")
    }
}
