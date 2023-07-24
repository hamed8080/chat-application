import SwiftUI
import ChatAppViewModels

public struct SendTextViewWithButtons: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var text: String
    var onSubmit: () -> Void
    var onCancel: () -> Void

    public init(text: String = "", onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.text = text
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    public var body: some View {
        HStack {
            Button(role: .destructive) {
                onCancel()
            } label: {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }

            MultilineTextField(text.isEmpty == true ? "Type message here ..." : "", text: $text, textColor: Color.black, mention: true)
                .cornerRadius(16)
                .onChange(of: viewModel.textMessage ?? "") { newValue in
                    viewModel.sendStartTyping(newValue)
                }

            Button {
                onSubmit()
            } label: {
                Label("Send", systemImage: "paperplane.fill")
                    .labelStyle(.iconOnly)
            }
        }
        .padding(.bottom, 4)
        .padding([.leading, .trailing], 8)
        .padding(.top, 18)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.clear)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24, corners: [.topRight, .topLeft])
            }
                .ignoresSafeArea()
        )
        .opacity(viewModel.thread.type == .channel && viewModel.thread.admin == false ? 0.3 : 1.0)
        .disabled(viewModel.thread.type == .channel && viewModel.thread.admin == false)
        .onReceive(viewModel.$editMessage) { editMessage in
            if let editMessage = editMessage {
                text = editMessage.message ?? ""
            }
        }
        .onChange(of: text) { newValue in
            viewModel.searchForParticipantInMentioning(newValue)
            viewModel.textMessage = newValue
        }
    }
}
