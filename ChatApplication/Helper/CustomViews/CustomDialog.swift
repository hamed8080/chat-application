//
//  CustomDialog.swift
//  ChatApplication
//
//  Created by Hamed on 1/15/22.
//

import SwiftUI

struct CustomDialog<DialogContent: View>: ViewModifier {
    @Binding private var isShowing: Bool
    private var dialogContent: DialogContent

    @Environment(\.colorScheme) var colorScheme

    init(isShowing: Binding<Bool>, @ViewBuilder dialogContent: @escaping () -> DialogContent) {
        _isShowing = isShowing
        self.dialogContent = dialogContent()
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                // the semi-transparent overlay
                Rectangle().foregroundColor(Color.black.opacity(0.6))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut, value: isShowing)
                VStack {
                    Spacer()
                    dialogContent
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .foregroundColor(Color(named: "background"))
                        )
                        .frame(maxWidth: 384)
                    Spacer()
                }
                .transition(.scale)
                .padding(16)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: isShowing ? 0.6 : 1, blendDuration: isShowing ? 1 : 0.2).speed(isShowing ? 1 : 3), value: isShowing)
    }
}

struct CustomDialog_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {}
            .preferredColorScheme(.dark)
            .customDialog(isShowing: .constant(true)) {
                VStack {
                    Text("Hello".uppercased())
                        .fontWeight(.bold)
                    Text("Message")

                    HStack {
                        Button("Hello") {}.buttonStyle(PrimaryButtonStyle(bgColor: Color.black.opacity(0.1)))

                        Button("Hello") {}.buttonStyle(PrimaryButtonStyle(bgColor: Color.pink.opacity(0.4)))
                    }
                }
                .padding()
            }
    }
}

extension View {
    func customDialog<DialogContent: View>(isShowing: Binding<Bool>, @ViewBuilder content: @escaping () -> DialogContent) -> some View {
        modifier(CustomDialog(isShowing: isShowing, dialogContent: content))
    }

    func dialog(_ title: String, _ message: String = "", _ iconName: String? = nil, _ isShowing: Binding<Bool>, onSubmit: @escaping (String) -> Void, onClose: (() -> Void)? = nil) -> some View {
        let dialog = {
            PrimaryCustomDialog(
                title: title,
                message: message,
                systemImageName: iconName,
                hideDialog: isShowing,
                onSubmit: onSubmit,
                onClose: onClose
            )
            .padding()
        }
        return modifier(CustomDialog(isShowing: isShowing, dialogContent: dialog))
    }
}
