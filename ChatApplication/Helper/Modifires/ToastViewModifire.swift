//
//  ToastViewModifire.swift
//  ChatApplication
//
//  Created by hamed on 3/15/22.
//

import SwiftUI

struct TopNotifyViewModifire: ViewModifier {
    @Binding private var isShowing: Bool
    let title: String?
    let message: String
    let image: Image?
    let duration: TimeInterval
    let backgroundColor: Color

    internal init(isShowing: Binding<Bool>, title: String? = nil, message: String, image: Image? = nil, duration: TimeInterval, backgroundColor: Color) {
        _isShowing = isShowing
        self.title = title
        self.message = message
        self.duration = duration
        self.image = image
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .animation(.easeInOut, value: isShowing)
                .blur(radius: isShowing ? 5 : 0)
            if isShowing {
                Rectangle()
                    .foregroundColor(Color.black.opacity(0.6))
                    .ignoresSafeArea()

                VStack {
                    toast
                        .background(
                            Rectangle()
                                .cornerRadius(24, corners: [.bottomRight, .bottomLeft])
                                .ignoresSafeArea()
                                .foregroundColor(backgroundColor)
                        )
                    Spacer()
                }
                .transition(.move(edge: .top))
            }
        }
        .onChange(of: isShowing, perform: { newValue in
            if newValue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        })
        .animation(.spring(response: isShowing ? 0.5 : 2, dampingFraction: isShowing ? 0.85 : 1, blendDuration: 1), value: isShowing)
    }

    private var toast: some View {
        VStack(spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(Color.black)
            }
            HStack(spacing: 0) {
                if let image = image {
                    image
                        .resizable()
                        .frame(width: 48, height: 48)
                        .cornerRadius(4)
                }
                Text(message)
                    .font(.subheadline)
                    .padding()
                    .foregroundColor(Color(named: "text_color_blue"))
                Spacer()
            }
        }
        .padding()
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, title: String? = nil, message: String, image: Image? = nil, duration: TimeInterval = 3, backgroundColor: Color = Color(named: "background")) -> some View {
        modifier(TopNotifyViewModifire(isShowing: isShowing, title: title, message: message, image: image, duration: duration, backgroundColor: backgroundColor))
    }
}

struct TestView: View {
    @State var isShowing = false

    var body: some View {
        Text("hello")
            .toast(isShowing: $isShowing,
                   title: "Test Title",
                   message: "Test message",
                   image: Image(uiImage: UIImage(named: "avatar.png")!))
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
