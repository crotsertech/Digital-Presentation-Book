import SwiftUI

struct TemplatePickerSheet: View {
    var onSelect: (BookTemplate, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customTitle: String = ""
    @State private var selectedTemplate: BookTemplate = .salesCall

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Customer name or topic", text: $customTitle)
                        .textInputAutocapitalization(.words)
                }

                Section("Template") {
                    ForEach(BookTemplate.allCases) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: template.iconSystemName)
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(template.accent, in: RoundedRectangle(cornerRadius: 9))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(template.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                if selectedTemplate == template {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("New from Template")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSelect(selectedTemplate, trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
