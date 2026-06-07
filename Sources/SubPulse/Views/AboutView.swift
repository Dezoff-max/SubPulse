import AppKit
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.subpulse.app"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

            VStack(spacing: 6) {
                Text("SubPulse")
                    .font(.largeTitle.bold())
                Text(L10n.text("aboutTagline", language: appLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                AboutRow(title: L10n.text("version", language: appLanguage), value: BundleInfo.displayVersion)
                Divider()
                AboutRow(title: L10n.text("developer", language: appLanguage), value: "@Rootoff")
                Divider()
                AboutRow(title: L10n.text("bundleIdentifier", language: appLanguage), value: bundleIdentifier)
                Divider()
                AboutRow(title: L10n.text("dataMode", language: appLanguage), value: L10n.text("localFirst", language: appLanguage))
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.8), in: RoundedRectangle(cornerRadius: 16))

            Text(L10n.text("aboutImportText", language: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(L10n.text("close", language: appLanguage)) {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 430)
    }
}

private struct AboutRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
