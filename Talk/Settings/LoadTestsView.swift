//
//  LoadTestsView.swift
//  Talk
//
//  Created by hamed on 2/21/24.
//

import SwiftUI
import TalkUI
import TalkExtensions
import TalkModels

struct LoadTestsView: View {
    @State private var threadId = ""
    @State private var start = ""
    @State private var end = ""

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    TextField("ThreadId".localized(bundle: Language.preferedBundle), text: $threadId)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "ThreadId")
                    TextField("Start".localized(bundle: Language.preferedBundle), text: $start)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "Start")
                    TextField("End".localized(bundle: Language.preferedBundle), text: $end)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "End")
                }
            } header: {
                Text("Rapid Send")
            }
        }.safeAreaInset(edge: .bottom) {
            SubmitBottomButton(text: "Start rapid Send") {
                LoadTests.rapidSend(threadId: Int(threadId)!,
                                    messageTempelate: LoadTests.longMessage,
                                    start: Int(start)!,
                                    end: Int(end)!)
            }
        }
    }
}
