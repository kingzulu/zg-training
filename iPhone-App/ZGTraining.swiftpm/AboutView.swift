import SwiftUI

/// Info-Seite zu Zulu Golf mit Link zur Homepage (wie in den anderen ZG-Apps).
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image("ZGLogoLarge")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                        .padding(.top, 24)
                        .accessibilityLabel("Zulu Golf")

                    Text("MIT HALTUNG AUF DEN PLATZ.")
                        .font(.caption.weight(.semibold))
                        .tracking(3)
                        .foregroundColor(.zuluYellow)
                        .padding(.top, 12)

                    Text("Das Ziel im Blick.")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("ZG-Training macht aus jedem Drill eine klare Aufgabe mit messbarem Score und plant das nächste Training nach deiner Fehlertendenz. Mit jedem Schlag ein Stück besser.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.75))

                    Link(destination: URL(string: "https://www.zulugolf.de")!) {
                        Label("zulugolf.de", systemImage: "arrow.up.right.square")
                            .font(.headline)
                            .foregroundColor(.zuluNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Capsule().fill(Color.zuluYellow))
                    }
                    .padding(.top, 8)

                    Text(version)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.zuluNavy.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(.zuluYellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
