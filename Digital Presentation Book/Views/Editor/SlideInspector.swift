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
                Toggle(isOn: $slide.isTemplate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use as Template")
                        Text("Templates appear in the +Add Slide menu so you can duplicate them. Image assets are shared, not re-uploaded.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Template")
            }

            Section {
                Toggle(isOn: $slide.isHidden) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide from Presentation")
                        Text("Hidden slides stay in the editor but are skipped when presenting.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Visibility")
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
