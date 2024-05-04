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
    @EnvironmentObject var galleryOffsetVM: GalleyOffsetViewModel
    let content: () -> Content
    let onDismiss: (() -> Void)?
    @State private var offsetY: CGFloat = 0

    public init(onDismiss: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            if viewModel.isPresented {
                if !viewModel.isError && !viewModel.isToast {
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .onTapGesture {
                            viewModel.dialogView = nil
                        }
                }
                content()
                    .transition(viewModel.transition)
                    .clipShape(RoundedRectangle(cornerRadius:(viewModel.radius)))
            }

            if viewModel.showCloseButton && viewModel.isPresented {
                DismissAppOverlayButton()
            }
        }
        .ignoresSafeArea(.all)
        .offset(y: offsetY)
        .simultaneousGesture(dragGesture)
        .animation(.smooth, value: offsetY)
        .animation(animtion, value: viewModel.isPresented)
        .onChange(of: viewModel.isPresented) { newValue in
            if newValue == false {
                offsetY = 0
                onDismiss?()
            }
        }
        .onChange(of: galleryOffsetVM.dragOffset) { newValue in
            if viewModel.isPresented, galleryOffsetVM.endScale == 1  {
                offsetY = newValue.height
            }
        }
    }

    var animtion: Animation {
        if viewModel.isPresented && !viewModel.isError {
            return Animation.interactiveSpring(response: 0.2, dampingFraction: 0.6, blendDuration: 0.2)
        } else {
            return Animation.easeInOut
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0, galleryOffsetVM.endScale == 1 {
                    offsetY = value.translation.height
                }
            }
            .onEnded { endValue in
                if endValue.translation.height > 100, galleryOffsetVM.endScale == 1 {
                    galleryOffsetVM.dismiss()
                } else {
                    withAnimation(.spring) {
                        offsetY = 0
                    }
                }
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
                        .foregroundColor(Color.App.accent)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
            }
            .padding(EdgeInsets(top: 48 + reader.safeAreaInsets.top, leading: 8, bottom: 0, trailing: 0))
        }
    }
}

struct AppOverlayView_Previews: PreviewProvider {
    struct Preview: View {
       @StateObject var viewModel = AppOverlayViewModel()

        var body: some View {
            AppOverlayView() {
                //
            } content: {
                Text("TEST")
            }
            .environmentObject(viewModel)
            .onAppear {
                viewModel.showCloseButton = true
                viewModel.isPresented = true
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
