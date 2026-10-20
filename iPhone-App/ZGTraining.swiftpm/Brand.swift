import SwiftUI

extension Color {
    /// Navy der Homepage zulugolf.de (#1b2233)
    static let zuluNavy = Color(red: 27 / 255, green: 34 / 255, blue: 51 / 255)
    /// Gelb aus dem ZG-Logo (#ffc20a)
    static let zuluYellow = Color(red: 255 / 255, green: 194 / 255, blue: 10 / 255)
    /// Logo-Blau, im Dunkelmodus heller (Asset „ZuluBlue“)
    static let zuluBlue = Color("ZuluBlue")
}

/// Navy-Kopfzeile mit Logo und Titel links und einem Knopf rechts,
/// genau wie in der Kurzspiel-App.
struct BrandToolbar: ViewModifier {
    let title: String
    let rightLabel: String
    let onBrand: () -> Void
    let onRight: () -> Void

    func body(content: Content) -> some View {
        styled(content)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.zuluNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func styled(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Ab iOS 26 legt das System sonst einen Glas-Rahmen um Logo und Titel.
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) { brandButton }
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .primaryAction) { rightButton }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) { brandButton }
                ToolbarItem(placement: .primaryAction) { rightButton }
            }
        }
    }

    // Tipp auf Logo oder Titel öffnet die Info-Seite zu Zulu Golf.
    private var brandButton: some View {
        Button(action: onBrand) {
            HStack(spacing: 10) {
                ZGLogoBadge()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Zeigt Infos zu Zulu Golf")
    }

    private var rightButton: some View {
        Button(rightLabel, action: onRight)
            .tint(.white)
    }
}

/// Das ZG-Logo von zulugolf.de in der Kopfzeile.
struct ZGLogoBadge: View {
    var body: some View {
        // Feste Größe und Originalfarben, sonst schrumpft oder verfärbt es sich.
        Image("ZGLogo")
            .renderingMode(.original)
            .resizable()
            .aspectRatio(480.0 / 306.0, contentMode: .fit)
            .frame(width: 38, height: 24)
            .fixedSize()
            .accessibilityLabel("Zulu Golf")
    }
}
