//
//  AttachmentButtons.swift
//  Talk
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels

struct AttachmentButtons: View {
    let viewModel: ActionSheetViewModel
    @Binding var showActionButtons: Bool

    var body: some View {
        MutableAttachmentDialog(showActionButtons: $showActionButtons)
            .environmentObject(viewModel)
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
    }
}

struct MutableAttachmentDialog: View {
    @Binding var showActionButtons: Bool
    @EnvironmentObject var viewModel: ActionSheetViewModel
    var threadVM: ThreadViewModel? { viewModel.threadViewModel }

    var body: some View {
        HStack(spacing: 8) {
            Spacer()

            AttchmentButtonItem(title: "General.gallery", image: "photo.fill") {
                threadVM?.sheetType = .galleryPicker
                showActionButtons.toggle()
                threadVM?.animateObjectWillChange()
            }

            Spacer()

            AttchmentButtonItem(title: "General.file", image: "doc.fill") {
                threadVM?.sheetType = .filePicker
                showActionButtons.toggle()
                threadVM?.animateObjectWillChange()
            }

            Spacer()

            AttchmentButtonItem(title: "General.location", image: "location.fill") {
                threadVM?.sheetType = .locationPicker
                showActionButtons.toggle()
                threadVM?.animateObjectWillChange()
            }

            Spacer()

            AttchmentButtonItem(title: "General.contact", image: "person.2.crop.square.stack.fill") {
                threadVM?.sheetType = .contactPicker
                showActionButtons.toggle()
                threadVM?.animateObjectWillChange()
            }
            .disabled(!EnvironmentValues.isTalkTest)
            .opacity(EnvironmentValues.isTalkTest ? 0.2 : 1.0)
            Spacer()
        }
        .font(.iransansBody)
        .padding()
    }
}

struct AttchmentButtonItem: View {
    let title: String
    let image: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State var isPressing = false

    var body: some View {
        VStack {
            ZStack {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.main)
            }
            .frame(width: isPressing ? 22 : 34, height: isPressing ? 22 : 34)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color.hint.opacity(0.5), lineWidth: 1, antialiased: true)
            )
            .overlay(alignment: .center) {
                if isPressing {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.clear)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(26)
                }
            }
            Text(String(localized: .init(title)))
                .font(.iransansCaption2)
                .foregroundStyle(Color.hint)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { newValue in
                    isPressing = true
                }
                .onEnded { newValue in
                    isPressing = false
                }
        )
        .animation(.easeInOut, value: isPressing)
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var viewModel: ActionSheetViewModel {
        let vm = ThreadViewModel(thread: MockData.thread)
        let viewModel = ActionSheetViewModel()
        viewModel.threadViewModel = vm
        return viewModel
    }

    static var previews: some View {
        AttachmentButtons(viewModel: viewModel, showActionButtons: .constant(false))
        //            AttchmentButtonItem(title: "Contacts", image: "person.fill") {
        //
        //            }

        //        AttachmentDialog(viewModel: viewModel)
    }
}
