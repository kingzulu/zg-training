import Foundation

/// Der Score einer Ausführung. Wird nie gespeichert, immer aus dem Lauf gerechnet.
struct Score {
    let punkte: Int
    let maxPunkte: Int
    let quoteJeStep: [Int: Double]
    /// Nur Stationen, die zur Quote zählen.
    let quoteJeGruppe: [ShotGroup: Double]
    /// Stationen, die separat ausgewiesen werden (z. B. der Putt im Pressure-Loop).
    let quoteNebenbei: [ShotGroup: Double]
    /// Nur bei Serien: Anzahl der Durchgänge.
    let durchgaenge: Int?
    let serieGeschafft: Bool

    var quote: Double {
        maxPunkte > 0 ? Double(punkte) / Double(maxPunkte) : 0
    }

    var prozent: Int {
        if let durchgaenge {
            return serieGeschafft ? max(0, 100 - 25 * (durchgaenge - 1)) : 0
        }
        return Int((quote * 100).rounded())
    }

    var anzeige: String {
        if let durchgaenge {
            return serieGeschafft
                ? "Serie im \(durchgaenge). Durchgang (\(prozent) %)"
                : "Keine Serie nach \(durchgaenge) Durchgängen"
        }
        return "\(punkte) von \(maxPunkte) Punkten (\(prozent) %)"
    }

    static func berechnen(_ run: DrillRun, drill: DrillTemplate) -> Score {
        let scoring = drill.scoring
        let bestePunkte = scoring.punkte(level: scoring.maxLevel)

        func zaehlt(_ shot: ShotResult) -> Bool {
            drill.steps.indices.contains(shot.step) && drill.steps[shot.step].zaehltZurQuote
        }

        func quote(_ shots: [ShotResult]) -> Double {
            guard !shots.isEmpty, bestePunkte > 0 else { return 0 }
            let summe = shots.reduce(0) { $0 + scoring.punkte(level: $1.level) }
            return Double(summe) / Double(shots.count * bestePunkte)
        }

        let gezaehlt = run.ergebnisse.filter(zaehlt)
        let punkte = gezaehlt.reduce(0) { $0 + scoring.punkte(level: $1.level) }

        let jeStep = Dictionary(grouping: gezaehlt, by: \.step).mapValues(quote)
        func jeGruppe(_ shots: [ShotResult]) -> [ShotGroup: Double] {
            let mitGruppe = shots.compactMap { shot -> (ShotGroup, ShotResult)? in
                guard let gruppe = drill.steps[shot.step].gruppe else { return nil }
                return (gruppe, shot)
            }
            return Dictionary(grouping: mitGruppe, by: { $0.0 }).mapValues { quote($0.map { $0.1 }) }
        }
        let nebenbei = run.ergebnisse.filter { !zaehlt($0) && drill.steps.indices.contains($0.step) }

        var durchgaenge: Int?
        var geschafft = false
        if case .serie(let laenge) = scoring {
            let letzter = run.ergebnisse.map(\.durchgang).max() ?? 0
            durchgaenge = letzter
            let imLetzten = run.ergebnisse.filter { $0.durchgang == letzter }
            geschafft = imLetzten.count >= laenge && imLetzten.allSatisfy { $0.level > 0 }
        }

        return Score(
            punkte: punkte,
            maxPunkte: gezaehlt.count * bestePunkte,
            quoteJeStep: jeStep,
            quoteJeGruppe: jeGruppe(gezaehlt),
            quoteNebenbei: jeGruppe(nebenbei),
            durchgaenge: durchgaenge,
            serieGeschafft: geschafft
        )
    }
}

/// Ein Eintrag im Trainingsplan, immer mit Begründung.
struct PlanItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var drillID: String
    var nurStep: Int?
    var grund: String
}

struct TrainingPlan: Codable {
    var datum: Date
    var items: [PlanItem]
    var notiz: String?
}

/// Ergebnis der Auswertung nach einem Drill.
struct Auswertung {
    let score: Score
    let gruende: [String]
    let zustand: DrillState
    let folgeDrills: [PlanItem]
    let ohneGruppen: Set<ShotGroup>
}

/// Die Regel-Engine: reine Funktionen ohne Zufall, damit jeder Vorschlag
/// nachvollziehbar ist. Jev (TypeSafe AI) kommt in Stufe 2 dazu; diese
/// Regeln bleiben dann das Sicherheitsnetz.
enum Engine {
    /// Eine Station oder Gruppe gilt als schwach, wenn ihre Quote so weit unter dem Rest liegt.
    static let schwachAbstand = 0.3
    /// Anteil der Fehler, ab dem eine Richtung als Tendenz gilt.
    static let tendenzAnteil = 0.5
    /// Mindestzahl an Fehlern in diese Richtung, bevor eine Tendenz zählt.
    static let minFehler = 3

    static func auswerten(_ run: DrillRun, drill: DrillTemplate, zustand alt: DrillState) -> Auswertung {
        let score = Score.berechnen(run, drill: drill)
        var zustand = alt
        zustand.hinweis = nil
        var gruende: [String] = []
        var folge: [PlanItem] = []
        var ohne: Set<ShotGroup> = []

        for regel in drill.regeln where erfuellt(regel.wenn, run: run, score: score, drill: drill) {
            gruende.append(regel.grund)
            for aktion in regel.dann {
                switch aktion {
                case .schwerer:
                    if zustand.stufe < drill.erschwerungen.count {
                        zustand.stufe += 1
                    } else {
                        gruende.append("Die schwerste Stufe ist schon erreicht.")
                    }
                case .leichter:
                    zustand.stufe = max(0, zustand.stufe - 1)
                case .schlaegerTausch(let von, let nach):
                    zustand.tausch[von.rawValue] = nach
                case .fokusDrill(let id):
                    folge.append(PlanItem(drillID: id, grund: regel.grund))
                case .fokusSchwacherStep:
                    if let step = schwacherStep(score) {
                        folge.append(PlanItem(drillID: drill.id, nurStep: step, grund: regel.grund))
                    }
                case .ohneGruppe(let gruppe):
                    ohne.insert(gruppe)
                case .hinweis(let text):
                    zustand.hinweis = text
                }
            }
        }

        if gruende.isEmpty {
            gruende.append("Keine Regel greift: Der Drill bleibt beim nächsten Mal gleich.")
        }
        return Auswertung(score: score, gruende: gruende, zustand: zustand,
                          folgeDrills: folge, ohneGruppen: ohne)
    }

    static func erfuellt(_ bedingung: RuleCondition, run: DrillRun, score: Score, drill: DrillTemplate) -> Bool {
        // Ein Schwerpunkt-Lauf mit nur einer Station hat weniger Bälle;
        // Punkte-Schwellen und Stationsvergleiche gelten dann nicht.
        let vollerLauf = run.nurStep == nil
        switch bedingung {
        case .punkteMindestens(let grenze):
            return vollerLauf && !drill.istSerie && score.punkte >= grenze
        case .punkteUnter(let grenze):
            return vollerLauf && !drill.istSerie && score.punkte < grenze
        case .tendenzUeberall(let laenge):
            return tendenz(run.ergebnisse, laenge)
        case .stepSchwach:
            return vollerLauf && schwacherStep(score) != nil
        case .gruppeSchwach(let gruppe):
            guard vollerLauf, let quote = score.quoteJeGruppe[gruppe] else { return false }
            let rest = score.quoteJeGruppe.filter { $0.key != gruppe }.map(\.value)
            guard !rest.isEmpty else { return false }
            return quote <= rest.reduce(0, +) / Double(rest.count) - schwachAbstand
        case .tendenzNachStufe(let stufe, let laenge):
            return tendenz(run.ergebnisse.filter { $0.level == stufe }, laenge)
        case .durchgaengeHoechstens(let grenze):
            guard let durchgaenge = score.durchgaenge else { return false }
            return score.serieGeschafft && durchgaenge <= grenze
        case .durchgaengeMehrAls(let grenze):
            guard let durchgaenge = score.durchgaenge else { return false }
            return durchgaenge > grenze
        }
    }

    static func tendenz(_ shots: [ShotResult], _ laenge: Laenge) -> Bool {
        let laengen = shots.compactMap { $0.miss?.laenge }
        let treffer = laengen.filter { $0 == laenge }.count
        guard treffer >= minFehler else { return false }
        return Double(treffer) / Double(laengen.count) >= tendenzAnteil
    }

    /// Die schwächste Station, wenn sie deutlich unter dem Schnitt der anderen liegt.
    static func schwacherStep(_ score: Score) -> Int? {
        guard score.quoteJeStep.count >= 2 else { return nil }
        let kandidaten = score.quoteJeStep.compactMap { step, quote -> (Int, Double)? in
            let andere = score.quoteJeStep.filter { $0.key != step }.map(\.value)
            let schnitt = andere.reduce(0, +) / Double(andere.count)
            return quote <= schnitt - schwachAbstand ? (step, quote) : nil
        }
        return kandidaten.min { $0.1 < $1.1 }?.0
    }

    /// Stellt den nächsten Trainingsplan zusammen: erst Folge-Drills aus den
    /// Regeln, dann was am längsten nicht dran war, zum Abschluss etwas, das gut lief.
    static func planen(katalog: [DrillTemplate], runs: [DrillRun], folgeDrills: [PlanItem],
                       ohneGruppen: Set<ShotGroup>, heute: Date = Date(), groesse: Int = 4) -> TrainingPlan {
        func erlaubt(_ id: String) -> Bool {
            guard let drill = katalog.first(where: { $0.id == id }) else { return false }
            if let bereich = drill.bereich, ohneGruppen.contains(bereich) { return false }
            return true
        }
        func schonDrin(_ items: [PlanItem], _ id: String) -> Bool {
            items.contains { $0.drillID == id }
        }

        var items: [PlanItem] = []
        for item in folgeDrills where items.count < groesse - 1 && erlaubt(item.drillID) {
            if !items.contains(where: { $0.drillID == item.drillID && $0.nurStep == item.nurStep }) {
                items.append(PlanItem(drillID: item.drillID, nurStep: item.nurStep, grund: item.grund))
            }
        }

        // Zum Abschluss: der Drill mit dem besten letzten Ergebnis (mindestens 60 %).
        let letzteRuns = Dictionary(runs.filter { $0.nurStep == nil }.map { ($0.drillID, $0) },
                                    uniquingKeysWith: { $0.datum > $1.datum ? $0 : $1 })
        let abschluss = katalog
            .filter { $0.imPlan && erlaubt($0.id) && !schonDrin(items, $0.id) }
            .compactMap { drill -> (DrillTemplate, Int)? in
                guard let run = letzteRuns[drill.id] else { return nil }
                let prozent = Score.berechnen(run, drill: drill).prozent
                return prozent >= 60 ? (drill, prozent) : nil
            }
            .max { $0.1 < $1.1 }

        let letztesDatum = Dictionary(runs.map { ($0.drillID, $0.datum) }, uniquingKeysWith: { max($0, $1) })
        let offen = katalog
            .filter { $0.imPlan && erlaubt($0.id) && !schonDrin(items, $0.id) && $0.id != abschluss?.0.id }
            .sorted { (letztesDatum[$0.id] ?? .distantPast) < (letztesDatum[$1.id] ?? .distantPast) }

        let platz = groesse - items.count - (abschluss == nil ? 0 : 1)
        for drill in offen.prefix(max(0, platz)) {
            items.append(PlanItem(drillID: drill.id, grund: grundFuerPause(letztesDatum[drill.id], heute: heute)))
        }
        if let abschluss {
            items.append(PlanItem(drillID: abschluss.0.id, grund: "Zum Abschluss: lief zuletzt gut (\(abschluss.1) %)."))
        }

        let notiz = ohneGruppen.isEmpty ? nil
            : "Heute ohne " + ohneGruppen.map(\.label).sorted().joined(separator: ", ") + "."
        return TrainingPlan(datum: heute, items: items, notiz: notiz)
    }

    static func grundFuerPause(_ datum: Date?, heute: Date) -> String {
        guard let datum else { return "Noch nie gespielt." }
        let tage = Calendar.current.dateComponents([.day], from: datum, to: heute).day ?? 0
        switch tage {
        case 14...: return "Seit \(tage) Tagen nicht geübt."
        case 0: return "Zuletzt heute gespielt."
        case 1: return "Zuletzt gestern gespielt."
        default: return "Zuletzt vor \(tage) Tagen gespielt."
        }
    }
}
