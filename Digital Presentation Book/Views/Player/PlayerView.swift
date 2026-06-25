import SwiftUI

// Bluetooth presenter remotes (Logitech R-series, Kensington, AirTurn,
// generic clickers) emulate a keyboard: arrows, Page Up/Down, "B" for
// blank, Space, etc. Everything routes through `onKeyPress` so any
// standard BLE HID clicker paired with the iPad/Mac works without setup.

struct PlayerView: View {
    let book: Book
    let package: DPBPackage

    @State private var currentSlideID: UUID?
    @State private var presenterMode: Bool = false
    @State private var sidebarVisible: Bool = true
    @State private var controlsVisibleInPresenter: Bool = true

    /// True when the salesperson has blacked out the slide to draw the
    /// prospect's attention to physical equipment / samples. Bluetooth
    /// clickers' "B" key, the `.` key, and the on-screen blackout button
    /// all toggle this. Pressing any navigation key while blanked first
    /// restores the slide (matching PowerPoint behavior).
    @State private var blanked: Bool = false

    /// Persists which side the control strip lives on across launches.
    @AppStorage("player.controlSide") private var controlSideRaw: String = ControlSide.trailing.rawValue

    @Environment(\.dismiss) private var dismiss

    private var controlSide: ControlSide {
        ControlSide(rawValue: controlSideRaw) ?? .trailing
    }

    var body: some View {
        ZStack {
            // Letterboxing reads as intentional cinema black, not a system
            // background, when this color fills the whole cover.
            Color.black.ignoresSafeArea()

            HStack(spacing: 0) {
                if sidebarVisible && !presenterMode {
                    ChapterSidebar(book: book, currentSlideID: $currentSlideID) { id in
                        currentSlideID = id
                    }
                    .frame(width: 260)
                    .background(.regularMaterial)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                slideStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(book.theme.backgroundColor.color)
            }
            .ignoresSafeArea(edges: presenterMode ? .all : [])

            // Blackout sits above the slide but below the control strip so
            // the rep can still operate controls while the screen is dark.
            if blanked {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityLabel("Screen blacked out")
            }

            if !presenterMode || controlsVisibleInPresenter {
                HStack {
                    if controlSide == .leading { controlStrip; Spacer() }
                    else { Spacer(); controlStrip }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .transition(.move(edge: controlSide == .leading ? .leading : .trailing)
                    .combined(with: .opacity))
            }
        }
        .animation(.snappy, value: presenterMode)
        .animation(.snappy, value: sidebarVisible)
        .animation(.snappy, value: controlsVisibleInPresenter)
        .animation(.snappy, value: controlSideRaw)
        .animation(.easeInOut(duration: 0.2), value: blanked)
        .onAppear { selectInitialSlideIfNeeded() }
        .focusable()
        .focusEffectDisabled()

        .onKeyPress(.rightArrow) { advance(by: 1);  return .handled }
        .onKeyPress(.leftArrow)  { advance(by: -1); return .handled }
        .onKeyPress(.downArrow)  { advance(by: 1);  return .handled }
        .onKeyPress(.upArrow)    { advance(by: -1); return .handled }
        .onKeyPress(.pageDown)   { advance(by: 1);  return .handled }
        .onKeyPress(.pageUp)     { advance(by: -1); return .handled }
        .onKeyPress(.space)      { advance(by: 1);  return .handled }
        .onKeyPress(.return)     { advance(by: 1);  return .handled }
        .onKeyPress(.home)       { jumpTo(.first);  return .handled }
        .onKeyPress(.end)        { jumpTo(.last);   return .handled }

        // Clickers with a dedicated "blank" button emit "b" or ".".
        .onKeyPress("b")         { blanked.toggle(); return .handled }
        .onKeyPress(".")         { blanked.toggle(); return .handled }

        .onKeyPress(.escape) {
            if blanked       { blanked = false; return .handled }
            if presenterMode { presenterMode = false; return .handled }
            return .ignored
        }

        .onTapGesture {
            if presenterMode {
                controlsVisibleInPresenter.toggle()
            }
        }
    }

    private var slideStage: some View {
        ZStack {
            if let slide = currentSlide {
                SlideCanvas(slide: slide, book: book, package: package)
                    .padding(presenterMode ? 0 : 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .id(slide.id)
            } else {
                ContentUnavailableView(
                    "This presentation is empty",
                    systemImage: "rectangle.dashed",
                    description: Text("Add a slide in the editor to get started.")
                )
            }
        }
        .animation(.snappy, value: currentSlideID)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 { advance(by: 1) }
                    else if value.translation.width > 50 { advance(by: -1) }
                }
        )
    }

    private var controlStrip: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 14) {
                glassButton(
                    systemImage: "xmark",
                    label: "Close",
                    tint: .red
                ) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                if !presenterMode {
                    glassButton(
                        systemImage: sidebarVisible ? "sidebar.leading" : "sidebar.squares.leading",
                        label: sidebarVisible ? "Hide outline" : "Show outline",
                        tint: nil
                    ) {
                        sidebarVisible.toggle()
                    }
                }

                glassButton(
                    systemImage: "chevron.left",
                    label: "Previous slide",
                    tint: .yellow
                ) {
                    advance(by: -1)
                }
                .disabled(globalIndex == 0)

                VStack(spacing: 2) {
                    Text(positionLabel)
                        .font(.callout.monospacedDigit().weight(.semibold))
                    if let slide = currentSlide, !slide.title.isEmpty {
                        Text(slide.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(width: 72)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))

                glassButton(
                    systemImage: "chevron.right",
                    label: "Next slide",
                    tint: .green
                ) {
                    advance(by: 1)
                }
                .disabled(globalIndex >= book.presentableSlides.count - 1)

                glassButton(
                    systemImage: blanked ? "eye.fill" : "eye.slash.fill",
                    label: blanked ? "Show slide" : "Black out screen",
                    tint: blanked ? .blue : nil
                ) {
                    blanked.toggle()
                }
                .keyboardShortcut("b", modifiers: [])

                glassButton(
                    systemImage: presenterMode ? "rectangle.compress.vertical" : "play.rectangle.fill",
                    label: presenterMode ? "Exit presenter" : "Present",
                    tint: nil
                ) {
                    presenterMode.toggle()
                    controlsVisibleInPresenter = true
                }
                .keyboardShortcut("p", modifiers: [.command])

                glassButton(
                    systemImage: controlSide == .trailing
                        ? "arrow.left.to.line"
                        : "arrow.right.to.line",
                    label: "Move controls",
                    tint: nil
                ) {
                    controlSideRaw = controlSide.toggled.rawValue
                }
            }
        }
    }

    /// Tinted Liquid Glass circular button. `tint = nil` gives the neutral
    /// variant used by utility buttons (sidebar/present/side-flip).
    @ViewBuilder
    private func glassButton(
        systemImage: String,
        label: String,
        tint: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(
            tint.map { Glass.regular.tint($0.opacity(0.55)).interactive() }
                ?? Glass.regular.interactive(),
            in: Circle()
        )
        .help(label)
        .accessibilityLabel(label)
    }

    private var currentSlide: Slide? {
        guard let id = currentSlideID else { return book.presentableSlides.first }
        return book.presentableSlides.first { $0.id == id }
    }

    private var globalIndex: Int {
        guard let id = currentSlideID else { return 0 }
        return book.presentableSlides.firstIndex { $0.id == id } ?? 0
    }

    private var positionLabel: String {
        let total = book.presentableSlides.count
        return total == 0 ? "0 / 0" : "\(globalIndex + 1) / \(total)"
    }

    private func selectInitialSlideIfNeeded() {
        if currentSlideID == nil {
            currentSlideID = book.presentableSlides.first?.id
        }
    }

    private func advance(by delta: Int) {
        // Any nav action while blanked restores the slide first, matching
        // PowerPoint behavior so a clicker press doesn't seem to do nothing.
        if blanked { blanked = false }
        let slides = book.presentableSlides
        guard !slides.isEmpty else { return }
        let next = max(0, min(slides.count - 1, globalIndex + delta))
        currentSlideID = slides[next].id
    }

    private enum JumpTarget { case first, last }

    private func jumpTo(_ target: JumpTarget) {
        if blanked { blanked = false }
        let slides = book.presentableSlides
        guard !slides.isEmpty else { return }
        switch target {
        case .first: currentSlideID = slides.first?.id
        case .last:  currentSlideID = slides.last?.id
        }
    }
}

private enum ControlSide: String {
    case leading, trailing

    var toggled: ControlSide {
        self == .leading ? .trailing : .leading
    }
}
