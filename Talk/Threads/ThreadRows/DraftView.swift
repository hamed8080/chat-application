//
//  DraftView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import SwiftUI
import TalkUI

struct DraftView: View {
    let draft: String

    var body: some View {
        Text("Thread.draft")
            .font(.iransansBody)
            .foregroundColor(.red)
        Text(draft)
            .font(.iransansBody)
            .foregroundColor(.secondaryLabel)
    }
}
