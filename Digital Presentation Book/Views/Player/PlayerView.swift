//
//  PlayerView.swift
//  Digital Presentation Book
//
//  Full presentation runtime. A vertical Liquid Glass control strip lives
//  on one of the short sides of the screen; a small toggle moves it from
//  the right edge to the left and back. The slide canvas fills everything
//  else.
//
//  Bluetooth presenter remotes (Logitech R-series, Kensington, AirTurn,
//  generic clickers) generally send arrow keys, Page Up/Down, B for blank,
//  or Space — all handled via `onKeyPress` so any standard BLE HID clicker
//  paired with the iPad / Mac advances slides without extra setup.
//

import SwiftUI

struct PlayerView: View {
    let book: Book
    let package: DPBPackage

    @State private var currentSlideID: UUID?
    @State private var presenterMode: Bool = false
    @State private var sidebarVisible: Bool = true
    @State private var controlsVisibleInPresenter: Bool = true

    /// Persists which side the control strip lives on across launches.
    @AppStorage("player.controlSide") private var controlSideRaw: String = ControlSide.trailing.rawValue

    @Environment(\.dismiss) private var dismiss

    private var controlSide: ControlSide {
        ControlSide(rawValue: controlSideRaw) ?? .trailing
    }

    var body: some View {
        ZStack {
            // Black bedrock fills the whole cover so letterboxing reads as
            // intentional cinema black instead of a system background.
            Color.black.ignoresSafeArea()

            // Slide + optional sidebar.
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

            // Floating side control strip.
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
        .onAppear { selectInitialSlideIfNeeded() }
        .focusable()
        .focusEffectDisabled()

        // Standard slide-advance keys. Covers the vast majority of
        // Bluetooth presenter remotes which emulate a keyboard.
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
        .onKeyPress(.escape) {
            if presenterMode { presenterMode = false; return .handled }
            return .ignored
        }

        // In presenter mode a tap on dead space toggles the chrome.
        .onTapGesture {
            if presenterMode {
                controlsVisibleInPresenter.toggle()
            }
        }
    }

    // MARK: - Slide stage

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

    // MARK: - Vertical control strip

    private var controlStrip: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 14) {
                // Close — red, destructive
                glassButton(
                    systemImage: "xmark",
                    label: "Close",
                    tint: .red
                ) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                // Sidebar toggle (chapter outline)
                if !presenterMode {
                    glassButton(
                        systemImage: sidebarVisible ? "sidebar.leading" : "sidebar.squares.leading",
                        label: sidebarVisible ? "Hide outline" : "Show outline",
                        tint: nil
                    ) {
                        sidebarVisible.toggle()
                    }
                }

                // Previous — yellow
                glassButton(
                    systemImage: "chevron.left",
                    label: "Previous slide",
                    tint: .yellow
                ) {
                    advance(by: -1)
                }
                .disabled(globalIndex == 0)

                // Position indicator
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

                // Next — green
                glassButton(
                    systemImage: "chevron.right",
                    label: "Next slide",
                    tint: .green
                ) {
                    advance(by: 1)
                }
                .disabled(globalIndex >= book.allSlides.count - 1)

                // Present / Exit-present
                glassButton(
                    systemImage: presenterMode ? "rectangle.compress.vertical" : "play.rectangle.fill",
                    label: presenterMode ? "Exit presenter" : "Present",
                    tint: nil
                ) {
                    presenterMode.toggle()
                    controlsVisibleInPresenter = true
                }
                .keyboardShortcut("p", modifiers: [.command])

                // Side toggle (move strip to the other short side)
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

    /// A tinted Liquid Glass circular button. Pass `tint = nil` for the
    /// neutral variant used by utility buttons (sidebar/present/side-flip).
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

    // MARK: - State helpers

    private var currentSlide: Slide? {
        guard let id = currentSlideID else { return book.allSlides.first }
        return book.allSlides.first { $0.id == id }
    }

    private var globalIndex: Int {
        guard let id = currentSlideID else { return 0 }
        return book.allSlides.firstIndex { $0.id == id } ?? 0
    }

    private var positionLabel: String {
        let total = book.allSlides.count
        return total == 0 ? "—" : "\(globalIndex + 1) / \(total)"
    }

    private func selectInitialSlideIfNeeded() {
        if currentSlideID == nil {
            currentSlideID = book.allSlides.first?.id
        }
    }

    private func advance(by delta: Int) {
        let slides = book.allSlides
        guard !slides.isEmpty else { return }
        let next = max(0, min(slides.count - 1, globalIndex + delta))
        currentSlideID = slides[next].id
    }

    private enum JumpTarget { case first, last }

    private func jumpTo(_ target: JumpTarget) {
        let slides = book.allSlides
        guard !slides.isEmpty else { return }
        switch target {
        case .first: currentSlideID = slides.first?.id
        case .last:  currentSlideID = slides.last?.id
        }
    }
}

// MARK: - Control side preference

private enum ControlSide: String {
    case leading, trailing

    var toggled: ControlSide {
        self == .leading ? .trailing : .leading
    }
}
