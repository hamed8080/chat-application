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
    let imageColor: Color

    internal init(isShowing: Binding<Bool>, title: String? = nil, message: String, image: Image? = nil, duration: TimeInterval, backgroundColor: Color, imageColor: Color = .clear) {
        _isShowing = isShowing
        self.title = title
        self.message = message
        self.duration = duration
        self.image = image
        self.imageColor = imageColor
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
                if let image = image {
                    image
                        .resizable()
                        .frame(width: 36, height: 36)
                        .cornerRadius(4)
                        .foregroundColor(imageColor)
                }
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
    func toast(isShowing: Binding<Bool>, title: String? = nil, message: String, image: Image? = nil, duration: TimeInterval = 3, backgroundColor: Color = .bgColor, imageColor: Color = .clear) -> some View {
        modifier(
            TopNotifyViewModifire(
                isShowing: isShowing,
                title: title,
                message: message,
                image: image,
                duration: duration,
                backgroundColor: backgroundColor,
                imageColor: imageColor
            )
        )
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
