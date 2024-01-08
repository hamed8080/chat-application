//
//  PinMessageDialog.swift
//
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import ChatModels
import TalkViewModels
import TalkModels

public struct PinMessageDialog: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var threadVM:ThreadViewModel
    let message: Message

    public init(message: Message) {
        self.message = message
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PinMessageDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 20) {
                Button {
                    threadVM.threadPinMessageViewModel.togglePinMessage(message, notifyAll: true)
                    appOverlayVM.dialogView = nil
                    threadVM.animateObjectWillChange()
                } label: {
                    Text("PinMessageDialog.pinAndNotify")
                        .foregroundStyle(Color.App.color3)
                        .font(.iransansBoldBody)
                }

                Button {
                    threadVM.threadPinMessageViewModel.togglePinMessage(message, notifyAll: false)
                    appOverlayVM.dialogView = nil
                    threadVM.animateObjectWillChange()
                } label: {
                    Text("PinMessageDialog.justPin")
                        .foregroundStyle(Color.App.color3)
                        .font(.iransansBoldBody)
                }

                Button {
                    appOverlayVM.dialogView = nil
                    threadVM.animateObjectWillChange()
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.iransansBoldBody)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 16, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct PinMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        PinMessageDialog(message: .init(id: 1))
    }
}
