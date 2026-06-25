# Digital Presentation Book

A SwiftUI iPad and Mac app for running and editing sales presentations offline.
Each presentation is a `.dpb` package (a zip with a `manifest.json` and an
`assets/` folder) that lives entirely on the device.

## What it does

- Build slides with text, images, video, shapes, and small interactive widgets.
- Group slides into chapters, mark slides as templates, hide slides you do not
  want to present, and add presenter notes.
- Run a presentation full screen with sidebar navigation, on-screen controls,
  and (on iOS) a small set of Bluetooth clicker keys.
- Import and export presentations as standalone `.dpb` files.

## Privacy

Nothing leaves the device. There is no analytics, no crash reporting, no
telemetry, and no bug-report upload pipeline of any kind. Presentations,
notes, and assets stay in the app sandbox.

## Feedback

Bug reports and feature requests go on the project's GitHub issues page.

Author: N. T. Crotser, ntc@crotser.dev

## License

MIT. See [LICENSE](LICENSE).

## Building

1. Open `Digital Presentation Book.xcodeproj` in Xcode 16 or newer.
2. The only third-party dependency is ZIPFoundation, vendored alongside the
   project. Swift Package Manager resolves it on first build.
3. Select an iPad or Mac run destination and build.
