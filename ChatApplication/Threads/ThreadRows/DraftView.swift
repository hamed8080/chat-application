//
//  DraftView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import ChatAppUI
import SwiftUI

struct DraftView: View {
    let draft: String

    var body: some View {
        Text("DRAFT:")
            .font(.iransansBody)
            .foregroundColor(.red)
        Text(draft)
            .font(.iransansBody)
            .foregroundColor(.secondaryLabel)
    }
}
