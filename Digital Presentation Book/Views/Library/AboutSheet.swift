import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    // TODO: fill in once the repo URL is final.
    private let githubURL: URL? = nil

    private let contactEmail = "ntc@crotser.dev"

    var body: some View {
        NavigationStack {
            Form {
                brandSection
                privacySection
                feedbackSection
                aboutSection
            }
            .formStyle(.grouped)
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var brandSection: some View {
        Section {
            HStack(spacing: 14) {
                BrandIcon()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Digital Presentation Book")
                        .font(.title3.bold())
                    Text(versionString)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var privacySection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing leaves this device")
                        .font(.subheadline.weight(.semibold))
                    Text("No analytics, no crash reports, no device telemetry, no bug-report uploads — ever. Your presentations and edits stay on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("Privacy")
        }
    }

    @ViewBuilder
    private var feedbackSection: some View {
        Section {
            if let url = githubURL {
                Link(destination: url) {
                    Label("Report a bug on GitHub", systemImage: "ladybug.fill")
                }
                Link(destination: url) {
                    Label("Request a feature on GitHub", systemImage: "lightbulb.fill")
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "ladybug.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 28)
                    Text("Bug reports and feature requests live on the project's GitHub page (link coming soon).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Feedback")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("License") {
                Text("MIT")
                    .font(.subheadline.weight(.medium))
            }
            LabeledContent("Author") {
                Text("N. T. Crotser")
                    .font(.subheadline.weight(.medium))
            }
            if let url = URL(string: "mailto:\(contactEmail)") {
                Link(destination: url) {
                    Label(contactEmail, systemImage: "envelope.fill")
                }
            } else {
                LabeledContent("Contact") {
                    Text(contactEmail)
                        .font(.subheadline.weight(.medium))
                }
            }
        } header: {
            Text("About")
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (\(build))"
    }
}
