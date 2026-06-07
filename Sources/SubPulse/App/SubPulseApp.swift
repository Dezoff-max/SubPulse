import AppKit
import SwiftData
import SwiftUI

private let fixedWindowWidth: CGFloat = 1120
private let defaultWindowHeight: CGFloat = 820
private let minimumWindowHeight: CGFloat = 760

@main
struct SubPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup("SubPulse") {
            ContentView()
                .modelContainer(AppModelContainer.shared)
                .frame(width: fixedWindowWidth)
                .frame(minHeight: minimumWindowHeight)
        }
        .defaultSize(width: fixedWindowWidth, height: defaultWindowHeight)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L10n.text("aboutSubPulse", language: appLanguage)) {
                    openWindow(id: "about")
                }
            }

            CommandGroup(after: .newItem) {
                Button(L10n.text("addSubscription", language: appLanguage)) {
                    NotificationCenter.default.post(name: .showSubscriptionEditor, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }

        Window(L10n.text("aboutSubPulse", language: appLanguage), id: "about") {
            let appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? AppAppearance.softNeumorphic.rawValue) ?? .softNeumorphic
            AboutView()
                .environment(\.isSoftNeumorphicTheme, appearance.isSoftNeumorphic)
                .preferredColorScheme(appearance.colorScheme)
                .background(appearance.isSoftNeumorphic ? SoftNeumorphicTheme.background : Color.clear)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lockedWindowWidth = fixedWindowWidth

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first, let screen = window.screen ?? NSScreen.main else { return }
            let visible = screen.visibleFrame
            let width = min(fixedWindowWidth, visible.width - 80)
            let height = min(defaultWindowHeight, visible.height - 60)
            let frame = NSRect(
                x: visible.midX - width / 2,
                y: visible.midY - height / 2,
                width: width,
                height: height
            )
            self.lockedWindowWidth = width
            window.delegate = self
            window.minSize = NSSize(width: width, height: minimumWindowHeight)
            window.maxSize = NSSize(width: width, height: .greatestFiniteMagnitude)
            window.contentMinSize = NSSize(width: width, height: minimumWindowHeight)
            window.contentMaxSize = NSSize(width: width, height: .greatestFiniteMagnitude)
            window.setFrame(frame, display: true, animate: false)
        }
    }

    private func clampWidth(of window: NSWindow) {
        guard abs(window.frame.width - lockedWindowWidth) > 0.5 else { return }
        var frame = window.frame
        frame.origin.x += (frame.width - lockedWindowWidth) / 2
        frame.size.width = lockedWindowWidth
        window.setFrame(frame, display: true, animate: false)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: lockedWindowWidth, height: max(frameSize.height, minimumWindowHeight))
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        clampWidth(of: window)
    }
}
