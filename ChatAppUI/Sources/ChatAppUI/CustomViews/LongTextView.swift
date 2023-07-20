//
//  LongTextView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

public struct LongTextView: View {
    @State private var expanded: Bool = false
    @State private var truncated: Bool = false
    @Namespace var id
    private var text: String

    public init(_ text: String) {
        self.text = text
    }

    private func determineTruncation(_ geometry: GeometryProxy) {
        let total = self.text.boundingRect(
            with: CGSize(
                width: geometry.size.width,
                height: .greatestFiniteMagnitude
            ),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )

        if total.size.height > geometry.size.height {
            self.truncated = true
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if expanded {
                Text(self.text)
                    .font(.system(size: 16))
                    .matchedGeometryEffect(id: 1, in: id, anchor: .top, isSource: false)
                    .multilineTextAlignment(text.naturalTextAlignment)
                    .lineLimit(nil)
            } else {
                Text(self.text)
                    .font(.system(size: 16))
                    .lineLimit(3)
                    .multilineTextAlignment(text.naturalTextAlignment)
                    .matchedGeometryEffect(id: 1, in: id, anchor: .bottom, isSource: true)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                self.determineTruncation(geometry)
                            }
                        }
                    )
            }
            if self.truncated {
                self.toggleButton
            }
        }
    }

    var toggleButton: some View {
        Button {
            withAnimation(.linear){
                self.expanded.toggle()
            }
        } label: {
            Text(self.expanded ? "Show less" : "Show more")
                .font(.caption)
        }
    }
}

struct LongTextView_Previews: PreviewProvider {
    static var previews: some View {
        LongTextView("Delap found no trace in employers’ records or in state archives which focused on segregation and detaining people. But she struck gold in The National Archives in Kew with a survey of ‘employment exchanges’ undertaken in 1955 to investigate how people then termed ‘subnormal’ or ‘mentally handicapped’ were being employed. She found further evidence in the inspection records of Trade Boards now held at Warwick University’s Modern Records Centre. In 1909, a complex system of rates and inspection emerged as part of an effort to set minimum wages. This led to the development of ‘exemption permits’ for a range of employees not considered to be worth ‘full’ payment.")
    }
}
