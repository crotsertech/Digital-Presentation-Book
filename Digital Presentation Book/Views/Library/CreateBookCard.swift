//
//  CreateBookCard.swift
//  Digital Presentation Book
//
//  Action tile shown in the Library's "Create" section. Visually distinct
//  from a real book card — dashed border and a single big icon — so the
//  user can tell creation actions from existing-book cards at a glance.
//

import SwiftUI

struct CreateBookCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let aspectRatio: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                preview
                metadata
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var preview: some View {
        ZStack {
            tint.opacity(0.08)

            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18
            )
        )
    }

    private var metadata: some View {
        HStack(spacing: 6) {
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HStack {
        CreateBookCard(
            title: "New Book",
            subtitle: "Start with a blank slide.",
            systemImage: "plus.rectangle.on.rectangle",
            tint: .blue,
            aspectRatio: 16.0 / 9.0,
            action: {}
        )
        .frame(width: 300)

        CreateBookCard(
            title: "From Template",
            subtitle: "Begin with a proven structure.",
            systemImage: "rectangle.stack.fill",
            tint: .indigo,
            aspectRatio: 16.0 / 9.0,
            action: {}
        )
        .frame(width: 300)
    }
    .padding()
    .background(.background.secondary)
}
