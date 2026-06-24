//
//  PlayerView.swift
//  Digital Presentation Book
//
//  Full presentation runtime: sidebar of chapters/slides on the left and
//  the active slide rendered at the book's aspect ratio on the right.
//  Supports swipe and keyboard navigation plus a distraction-free
//  presenter mode that hides all chrome.
//

import SwiftUI

struct PlayerView: View {
    let book: Book
    let package: DPBPackage

    @State private var currentSlideID: UUID?
    @State private var presenterMode: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if presenterMode {
                presenterModeBody
            } else {
                splitBody
            }
        }
        .onAppear { selectInitialSlideIfNeeded() }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.rightArrow) { advance(by: 1); return .handled }
        .onKeyPress(.leftArrow)  { advance(by: -1); return .handled }
        .onKeyPress(.space)      { advance(by: 1); return .handled }
        .onKeyPress(.escape) {
            if presenterMode { presenterMode = false; return .handled }
            return .ignored
        }
    }

    // MARK: - Layouts

    private var splitBody: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ChapterSidebar(book: book, currentSlideID: $currentSlideID) { id in
                currentSlideID = id
            }
            .navigationTitle(book.title)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            slideStage
                .navigationTitle("")
                .toolbar { toolbarContent }
        }
    }

    private var presenterModeBody: some View {
        slideStage
            .background(.black)
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                Button {
                    presenterMode = false
                } label: {
                    Image(systemName: "rectangle.compress.vertical")
                        .padding(12)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
    }

    private var slideStage: some View {
        ZStack {
            book.theme.backgroundColor.color
                .opacity(presenterMode ? 1.0 : 0.0)

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
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 { advance(by: 1) }
                    else if value.translation.width > 50 { advance(by: -1) }
                }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                dismiss()
            } label: {
                Label("Library", systemImage: "books.vertical")
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                advance(by: -1)
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(globalIndex == 0)

            Text(positionLabel)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                advance(by: 1)
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .disabled(globalIndex >= book.allSlides.count - 1)

            Button {
                presenterMode = true
            } label: {
                Label("Present", systemImage: "play.rectangle.fill")
            }
            .keyboardShortcut("p", modifiers: [.command])
        }
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
}
