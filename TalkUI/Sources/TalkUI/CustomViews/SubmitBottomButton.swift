//
//  SubmitBottomButton.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct SubmitBottomButton: View {
    @Binding var isLoading: Bool
    @Binding var enableButton: Bool
    let text: String
    let color: Color = .main
    let action: (()-> Void)?

    public init(text: String,
                enableButton: Binding<Bool> = .constant(true),
                isLoading: Binding<Bool> = .constant(false),
                action: (()-> Void)? = nil)
    {
        self.action = action
        self._enableButton = enableButton
        self._isLoading = isLoading
        self.text = text
    }

    public var body: some View {
        HStack {
            Button {
                withAnimation {
                    action?()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text(String(localized: .init(text)))
                        .font(.iransansBody)
                        .contentShape(Rectangle())
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .frame(height: 48)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(Color.main)
            .cornerRadius(8)
            .disabled(!enableButton)
            .opacity(enableButton ? 1.0 : 0.3)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct SumbitBottomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SubmitBottomButton(text: "TEST", enableButton: .constant(false), isLoading: .constant(false)) {

            }
            SubmitBottomButton(text: "TEST", enableButton: .constant(true), isLoading: .constant(true)) {

            }
            SubmitBottomButton(text: "TEST", enableButton: .constant(true), isLoading: .constant(false)) {

            }
        }
    }
}
