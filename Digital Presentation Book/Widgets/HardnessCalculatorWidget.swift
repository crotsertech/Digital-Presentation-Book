import SwiftUI

// Interactive widget for water-treatment sales calls. The rep enters the
// prospect's hardness reading (GPG) and household size; the widget shows the
// severity bucket, estimated annual hidden costs, and a suggested treatment
// tier.

@MainActor
struct HardnessCalculatorWidget: SlideWidget {
    static let widgetID = "com.starholder.dpb.widget.hardness-calculator"
    static let displayName = "Hardness Cost Calculator"
    static let summary = "Annual cost of hard water based on GPG and household size."
    static let iconSystemName = "drop.triangle.fill"

    static var defaultParameters: [String: WidgetParameterValue] {
        [
            "initialGPG": .number(10),
            "initialHousehold": .number(4),
            "showRecommendation": .bool(true)
        ]
    }

    static func makeView(parameters: [String: WidgetParameterValue]) -> AnyView {
        AnyView(HardnessCalculatorView(parameters: parameters))
    }
}

private struct HardnessCalculatorView: View {
    let parameters: [String: WidgetParameterValue]

    @State private var grainsPerGallon: Double = 10
    @State private var householdSize: Int = 4

    private var showRecommendation: Bool {
        parameters.bool("showRecommendation", default: true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 12) {
                gpgRow
                householdRow
            }

            Divider()

            resultsGrid

            if showRecommendation {
                recommendation
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .onAppear {
            grainsPerGallon = parameters.number("initialGPG", default: 10)
            householdSize = Int(parameters.number("initialHousehold", default: 4))
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.triangle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text("Your Water Today")
                    .font(.title3.bold())
                Text("Adjust the sliders to see what hard water is costing your home each year.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var gpgRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Hardness")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(grainsPerGallon, specifier: "%.1f") GPG")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $grainsPerGallon, in: 0...40, step: 0.5)
            Text(severityLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(severityColor)
        }
    }

    private var householdRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Household Size")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(householdSize) people")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Stepper(value: $householdSize, in: 1...10) {
                EmptyView()
            }
            .labelsHidden()
        }
    }

    private var resultsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
            GridRow {
                resultCell(label: "Soap & detergent", value: annualSoapCost)
                resultCell(label: "Water heater efficiency", value: heaterLossCost)
            }
            GridRow {
                resultCell(label: "Appliance lifespan", value: applianceCost)
                resultCell(label: "Estimated total / year", value: totalAnnualCost, emphasized: true)
            }
        }
    }

    private func resultCell(label: String, value: Double, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(currency(value))
                .font(emphasized ? .title.bold() : .title3.weight(.semibold))
                .foregroundStyle(emphasized ? Color.accentColor : Color.primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendation: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendationIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(severityColor, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendationTitle)
                    .font(.headline)
                Text(recommendationDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(severityColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Calculations

    /// USGS/water-quality industry buckets: soft <1, slight 1-3, moderate 3-7,
    /// hard 7-10, very hard 10-14, extremely hard >14.
    private var severityLabel: String {
        switch grainsPerGallon {
        case ..<1:    return "Soft"
        case ..<3:    return "Slightly hard"
        case ..<7:    return "Moderately hard"
        case ..<10:   return "Hard"
        case ..<14:   return "Very hard"
        default:      return "Extremely hard"
        }
    }

    private var severityColor: Color {
        switch grainsPerGallon {
        case ..<3:  return .green
        case ..<7:  return .yellow
        case ..<10: return .orange
        case ..<14: return .red
        default:    return .purple
        }
    }

    /// Industry studies suggest hard water increases soap/detergent usage by
    /// roughly 25–50% above moderately-hard. We use a per-person yearly
    /// baseline and scale it by GPG.
    private var annualSoapCost: Double {
        let perPersonBaseline = 140.0
        let multiplier = max(0, (grainsPerGallon - 3.0)) * 0.04
        return perPersonBaseline * multiplier * Double(householdSize)
    }

    /// Scale buildup on heating elements degrades efficiency. Rough estimate
    /// at ~$8/year per GPG per person from utility-cost increases.
    private var heaterLossCost: Double {
        grainsPerGallon * 8.0 * Double(householdSize)
    }

    /// Hard water shortens dishwasher/washer/water-heater lifespans. We
    /// amortize early replacement against the household.
    private var applianceCost: Double {
        let baselinePerHome = 75.0
        let multiplier = max(0, grainsPerGallon - 3.0) * 0.18
        return baselinePerHome * multiplier
    }

    private var totalAnnualCost: Double {
        annualSoapCost + heaterLossCost + applianceCost
    }

    private var recommendationIcon: String {
        switch grainsPerGallon {
        case ..<3:  return "checkmark"
        case ..<10: return "drop.fill"
        default:    return "exclamationmark.triangle.fill"
        }
    }

    private var recommendationTitle: String {
        switch grainsPerGallon {
        case ..<3:  return "Your water is in great shape"
        case ..<7:  return "A compact softener would polish this off"
        case ..<10: return "A whole-home softener is the right fit"
        case ..<14: return "Upgrade to a high-efficiency softener"
        default:    return "Premium twin-tank softener recommended"
        }
    }

    private var recommendationDetail: String {
        let savings = currency(totalAnnualCost)
        return "Treating your water could save approximately \(savings) every year."
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#Preview {
    HardnessCalculatorView(parameters: HardnessCalculatorWidget.defaultParameters)
        .frame(width: 600, height: 460)
        .padding()
}
