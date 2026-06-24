//
//  WidgetPickerSheet.swift
//  Digital Presentation Book
//
//  Modal sheet listing every widget the WidgetRegistry knows about.
//  Tapping one returns its metatype so the editor can insert it.
//

import SwiftUI

struct WidgetPickerSheet: View {
    var onSelect: (SlideWidget.Type) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(WidgetRegistry.all.indices, id: \.self) { idx in
                    let widget = WidgetRegistry.all[idx]
                    Button {
                        onSelect(widget)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: widget.iconSystemName)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.tint, in: RoundedRectangle(cornerRadius: 9))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(widget.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(widget.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Widget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
