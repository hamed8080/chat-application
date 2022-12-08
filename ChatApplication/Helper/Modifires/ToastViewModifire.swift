//
//  ToastViewModifire.swift
//  ChatApplication
//
//  Created by hamed on 3/15/22.
//

import SwiftUI

struct TopNotifyViewModifire: ViewModifier {
    @Binding
    private var isShowing: Bool
    let title: String?
    let message: String
    let image: AnyView?
    let duration: TimeInterval

    internal init(isShowing: Binding<Bool>, title: String? = nil, message: String, image: AnyView? = nil, duration: TimeInterval) {
        self._isShowing = isShowing
        self.title = title
        self.message = message
        self.duration = duration
        self.image = image
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
                                .background(.ultraThinMaterial)
                        )
                    Spacer()
                }
                .transition(.move(edge: .top))
            }
        }
        .onChange(of: isShowing) { newValue in
            if newValue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
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
    func toast(isShowing: Binding<Bool>, title: String? = nil, message: String, image: AnyView? = nil, duration: TimeInterval = 3) -> some View {
        modifier(TopNotifyViewModifire(isShowing: isShowing, title: title, message: message, image: image, duration: duration))
    }
}

struct TestView: View {
    @State
    var isShowing = false

    var body: some View {
        Text("hello")
            .toast(isShowing: $isShowing,
                   title: "Test Title",
                   message: "Test message",
                   image: AnyView(
                    Image(systemName: "record.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.red)
                        .cornerRadius(4)
                   )
            )
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
