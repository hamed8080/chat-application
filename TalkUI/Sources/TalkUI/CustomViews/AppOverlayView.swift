//
//  AppOverlayView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI
import TalkViewModels

public struct AppOverlayView<Content>: View where Content: View {
    @EnvironmentObject var viewModel: AppOverlayViewModel
    let content: () -> Content
    let onDismiss: (() -> Void)?
    let showCloseButton: Bool
    var isError: Bool { AppState.shared.error != nil }

    public init(showCloseButton: Bool = true, onDismiss: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.showCloseButton = showCloseButton
        self.content = content
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            if viewModel.isPresented {
                if !isError {
                    LinearGradient(colors: [.orange.opacity(0.15), .orange.opacity(0.05)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                content()
                    .transition(.asymmetric(insertion: isError ? .push(from: .top) : .scale, removal: .move(edge: isError ? .top : .bottom)))
            }

            if showCloseButton && viewModel.isPresented {
                DismissAppOverlayButton()
            }
        }
        .ignoresSafeArea(.all)
        .animation(animtion, value: viewModel.isPresented)
        .onChange(of: viewModel.isPresented) { newValue in
            if newValue == false {
                onDismiss?()
            }
        }
    }

    var animtion: Animation {
        if viewModel.isPresented && !isError {
            return Animation.interactiveSpring(response: 0.2, dampingFraction: 0.6, blendDuration: 0.2)
        } else {
            return Animation.easeInOut
        }
    }
}

struct DismissAppOverlayButton: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel

    var body: some View {
        GeometryReader { reader in
            VStack {
                Button {
                    withAnimation {
                        appOverlayVM.isPresented = false
                        appOverlayVM.clear()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundColor(Color.App.primary)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .padding(.top, 48 + reader.safeAreaInsets.top)
            .padding(.leading, 8)
        }
    }
}

struct AppOverlayView_Previews: PreviewProvider {
    struct Preview: View {
       @StateObject var viewModel = AppOverlayViewModel()

        var body: some View {
            AppOverlayView(showCloseButton: true) {
                //
            } content: {
                Text("TEST")
            }
            .environmentObject(viewModel)
            .onAppear {
                viewModel.isPresented = true
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
