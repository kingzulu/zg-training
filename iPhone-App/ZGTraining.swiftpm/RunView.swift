import SwiftUI

/// Erfassung auf der Range: ein Tipp pro Ball, bei Fehlern optional die Richtung.
struct RunView: View {
    let drill: DrillTemplate
    let planItem: PlanItem?

    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State private var ergebnisse: [ShotResult] = []
    @State private var offenerBall: ShotResult?
    @State private var auswertung: Auswertung?

    private var nurStep: Int? { planItem?.nurStep }

    private var serieLaenge: Int? {
        if case .serie(let laenge) = drill.scoring { return laenge }
        return nil
    }

    /// Station je Ball. Ein Schwerpunkt-Lauf spielt eine Station mit doppelter Ballzahl.
    private var reihenfolge: [Int] {
        drill.steps.indices
            .filter { nurStep == nil || $0 == nurStep }
            .flatMap { Array(repeating: $0, count: drill.steps[$0].baelle * (nurStep == nil ? 1 : 2)) }
    }

    private var aktuellerDurchgang: Int {
        guard let letzter = ergebnisse.last else { return 1 }
        return letzter.level == 0 ? letzter.durchgang + 1 : letzter.durchgang
    }

    private var imDurchgang: Int {
        ergebnisse.filter { $0.durchgang == aktuellerDurchgang }.count
    }

    private var fertig: Bool {
        guard let laenge = serieLaenge else { return ergebnisse.count >= reihenfolge.count }
        if let letzter = ergebnisse.last {
            let imLetzten = ergebnisse.filter { $0.durchgang == letzter.durchgang }
            if imLetzten.count >= laenge && imLetzten.allSatisfy({ $0.level > 0 }) { return true }
        }
        if let max = drill.maxDurchgaenge, aktuellerDurchgang > max { return true }
        return false
    }

    private var naechsterStep: Int {
        serieLaenge == nil ? reihenfolge[ergebnisse.count] : 0
    }

    private var ballText: String {
        if let laenge = serieLaenge {
            return "Durchgang \(aktuellerDurchgang) · Putt \(imDurchgang + 1) von \(laenge)"
        }
        return "Ball \(ergebnisse.count + 1) von \(reihenfolge.count)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let auswertung {
                    ErgebnisView(drill: drill, auswertung: auswertung) { dismiss() }
                } else if fertig {
                    fertigCard
                } else {
                    aufgabeCard
                    if let offenerBall {
                        FehlerAuswahl(gruppe: drill.steps[offenerBall.step].gruppe) { miss in
                            var shot = offenerBall
                            shot.miss = miss.istLeer ? nil : miss
                            ergebnisse.append(shot)
                            self.offenerBall = nil
                        }
                    } else {
                        tasten
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(drill.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.zuluNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if offenerBall != nil {
                        offenerBall = nil
                    } else if !ergebnisse.isEmpty {
                        ergebnisse.removeLast()
                    }
                } label: {
                    Label("Rückgängig", systemImage: "arrow.uturn.backward")
                }
                .tint(.white)
                .disabled(auswertung != nil || (ergebnisse.isEmpty && offenerBall == nil))
            }
        }
    }

    private var aufgabeCard: some View {
        let step = drill.steps[naechsterStep]
        return VStack(alignment: .leading, spacing: 8) {
            Text(ballText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.zuluBlue)
            Text(step.club.label)
                .font(.largeTitle.bold())
            Text(step.target.label)
                .font(.title3)
            if let schwung = step.schwung {
                Label(schwung.label, systemImage: "clock")
                    .font(.headline)
            }
            if let regel = drill.routineRegel {
                Text(regel).font(.footnote).foregroundStyle(.secondary)
            }
            if let hinweis = store.zustand(drill.id).hinweis {
                Label(hinweis, systemImage: "lightbulb")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var tasten: some View {
        VStack(spacing: 10) {
            ForEach(drill.scoring.optionen) { option in
                let beste = option.level == drill.scoring.maxLevel
                Button {
                    let shot = ShotResult(step: naechsterStep,
                                          durchgang: serieLaenge == nil ? 1 : aktuellerDurchgang,
                                          level: option.level, miss: nil)
                    if beste { ergebnisse.append(shot) } else { offenerBall = shot }
                } label: {
                    Text(option.label)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(beste ? Color.zuluBlue : (option.level == 0 ? Color.gray : Color.zuluBlue.opacity(0.6)))
            }
        }
    }

    private var fertigCard: some View {
        VStack(spacing: 16) {
            Text("Alle Bälle erfasst")
                .font(.title2.bold())
            Button {
                let run = DrillRun(drillID: drill.id, datum: Date(),
                                   stufe: store.zustand(drill.id).stufe,
                                   nurStep: nurStep, planItemID: planItem?.id,
                                   ergebnisse: ergebnisse)
                auswertung = store.abschliessen(run)
            } label: {
                Text("Auswerten")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.zuluNavy)
        }
        .padding()
    }
}

/// Nach einem Fehler: wohin ging der Ball? Alles optional.
private struct FehlerAuswahl: View {
    let gruppe: ShotGroup?
    let fertig: (Miss) -> Void
    @State private var miss = Miss()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wohin ging der Ball?").font(.headline)
            HStack {
                auswahl("Links", aktiv: miss.richtung == .links) { miss.richtung = miss.richtung == .links ? nil : .links }
                auswahl("Rechts", aktiv: miss.richtung == .rechts) { miss.richtung = miss.richtung == .rechts ? nil : .rechts }
            }
            HStack {
                auswahl("Zu kurz", aktiv: miss.laenge == .kurz) { miss.laenge = miss.laenge == .kurz ? nil : .kurz }
                auswahl("Zu lang", aktiv: miss.laenge == .lang) { miss.laenge = miss.laenge == .lang ? nil : .lang }
            }
            Button {
                fertig(miss)
            } label: {
                Text("Weiter")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.zuluNavy)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func auswahl(_ text: String, aktiv: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
        .tint(aktiv ? Color.zuluBlue : Color.gray)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(aktiv ? Color.zuluBlue : .clear, lineWidth: 2)
        )
    }
}

/// Score und Begründung, was beim nächsten Mal anders wird.
private struct ErgebnisView: View {
    let drill: DrillTemplate
    let auswertung: Auswertung
    let fertig: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(auswertung.score.anzeige)
                .font(.title.bold())

            let gruppen = auswertung.score.quoteJeGruppe
            if gruppen.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nach Bereichen").font(.headline)
                    ForEach(ShotGroup.allCases, id: \.self) { gruppe in
                        if let quote = gruppen[gruppe] {
                            zeile(gruppe.label, quote)
                        }
                    }
                    ForEach(ShotGroup.allCases, id: \.self) { gruppe in
                        if let quote = auswertung.score.quoteNebenbei[gruppe] {
                            zeile("\(gruppe.label) (separat)", quote)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Nächstes Mal").font(.headline)
                ForEach(auswertung.gruende, id: \.self) { grund in
                    Label(grund, systemImage: "arrow.forward.circle")
                }
                if let hinweis = auswertung.zustand.hinweis {
                    Label(hinweis, systemImage: "lightbulb")
                }
            }

            Button(action: fertig) {
                Text("Fertig")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.zuluNavy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func zeile(_ text: String, _ quote: Double) -> some View {
        HStack {
            Text(text)
            Spacer()
            Text("\(Int((quote * 100).rounded())) %").monospacedDigit().fontWeight(.semibold)
        }
    }
}
