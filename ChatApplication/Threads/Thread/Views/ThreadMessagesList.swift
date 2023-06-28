//
//  ThreadMessagesList.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct ThreadMessagesList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var isInEditMode: Binding<Bool>
    @State var scrollingUP = false
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollViewHeight = CGFloat.infinity
    @Namespace var scrollViewNameSpace

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ListLoadingView(isLoading: $viewModel.isLoading)
                    ForEach(viewModel.messages) { message in
                        MessageRowFactory(message: message, calculation: MessageRowCalculationViewModel(), isInEditMode: isInEditMode)
                            .id(message.uniqueId)
                            .transition(.asymmetric(insertion: .opacity, removal: .slide))
                            .onAppear {
                                viewModel.sendSeenMessageIfNeeded(message)
                                viewModel.setIfNeededToScrollToTheLastPosition(scrollingUP, message)
                            }
                    }
                    ListLoadingView(isLoading: $viewModel.isLoading)
                }
                .background(
                    GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }
                )
                .padding(.bottom)
                .padding([.leading, .trailing])
            }
            .overlay {
                goToBottomOfThread(scrollView: scrollView)
            }
            .safeAreaInset(edge: .top) {
                Spacer()
                    .frame(height: viewModel.thread?.pinMessages?.count ?? 0 > 0 ? 48 : 0)
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: 48)
            }
            .background(
                background
            )
            .simultaneousGesture(
                DragGesture().onChanged { value in
                    scrollingUP = value.translation.height > 0
                }
            )
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { originY in
                if originY < 64, scrollingUP {
                    viewModel.loadMoreMessage()
                }
            }
            .onReceive(viewModel.$scrollToUniqueId) { uniqueId in
                guard let uniqueId = uniqueId else { return }
                withAnimation {
                    scrollView.scrollTo(uniqueId, anchor: .bottom)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    @ViewBuilder
    func goToBottomOfThread(scrollView _: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.scrollToBottom()
                } label: {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundColor(Color.gray)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                .frame(width: 36, height: 36)
                .background(Color.white)
                .cornerRadius(36)
            }
            .padding(.bottom, 16)
            .padding([.trailing], 8)
        }
    }

    var background: some View {
        Image("chat_bg")
            .resizable(resizingMode: .tile)
            .renderingMode(.template)
            .opacity(colorScheme == .dark ? 0.9 : 0.25)
            .colorInvert()
            .colorMultiply(colorScheme == .dark ? Color.white : Color.cyan)
            .overlay {
                let darkColors: [Color] = [.gray.opacity(0.5), .white.opacity(0.001)]
                let lightColors: [Color] = [.white.opacity(0.1), .gray.opacity(0.5)]
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? darkColors : lightColors),
                               startPoint: .top,
                               endPoint: .bottom)
            }
    }
}

struct ThreadMessagesList_Previews: PreviewProvider {
    static var previews: some View {
        ThreadMessagesList(isInEditMode: .constant(true))
    }
}
