import SwiftUI
import TalkViewModels

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
                Label("General.close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }

            MultilineTextField(text.isEmpty == true ? String(localized: .init("General.typeMessageHere")) : "", text: $text, textColor: UIColor(named: "message_text"), mention: true)
                .clipShape(RoundedRectangle(cornerRadius:(16)))
                .onChange(of: viewModel.sendContainerViewModel.textMessage) { newValue in
                    viewModel.sendStartTyping(newValue)
                }

            Button {
                onSubmit()
            } label: {
                Label("General.send", systemImage: "paperplane.fill")
                    .labelStyle(.iconOnly)
            }
        }
        .padding(EdgeInsets(top: 18, leading: 8, bottom: 4, trailing: 8))
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
        .opacity(viewModel.thread.type?.isChannelType == true && viewModel.thread.admin == false ? 0.3 : 1.0)
        .disabled(viewModel.thread.type?.isChannelType == true && viewModel.thread.admin == false)
        .onReceive(viewModel.sendContainerViewModel.$editMessage) { editMessage in
            if let editMessage = editMessage {
                text = editMessage.message ?? ""
            }
        }
        .onChange(of: text) { newValue in
            viewModel.sendContainerViewModel.textMessage = newValue
        }
    }
}
