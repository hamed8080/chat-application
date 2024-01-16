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
            .foregroundColor(Color.App.red)
        Text(draft)
            .lineLimit(1)
            .font(.iransansBody)
            .foregroundColor(Color.App.textSecondary)
    }
}
