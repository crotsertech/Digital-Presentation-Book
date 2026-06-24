//
//  SlideInspector.swift
//  Digital Presentation Book
//
//  Right-side inspector shown when no element is selected. Edits the
//  current slide's title and presenter notes.
//

import SwiftUI

struct SlideInspector: View {
    @Binding var slide: Slide

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.teal, in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Slide")
                            .font(.headline)
                        Text("Tap an element on the canvas to edit it.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            Section("Title") {
                TextField("Slide title", text: $slide.title, axis: .vertical)
                    .lineLimit(1...3)
            }

            Section {
                TextField(
                    "Presenter notes (not shown to the audience)",
                    text: $slide.notes,
                    axis: .vertical
                )
                .lineLimit(4...12)
            } header: {
                Text("Presenter Notes")
            } footer: {
                Text("Only visible to you while editing.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Slide")
    }
}
