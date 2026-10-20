import Foundation

/// Hält alle Trainingsdaten und speichert sie als JSON-Datei auf dem iPhone.
@MainActor
final class TrainingStore: ObservableObject {
    struct Daten: Codable {
        var runs: [DrillRun] = []
        var zustaende: [String: DrillState] = [:]
        var folgeDrills: [PlanItem] = []
        var ohneGruppen: Set<ShotGroup> = []
        var plan: TrainingPlan?
    }

    @Published private(set) var daten: Daten {
        didSet { save() }
    }

    let katalog = Katalog.alle

    /// Die Datei liegt im Dokumente-Ordner und kann geteilt werden.
    static var dateiURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("zg-training.json")
    }

    init() {
        if let data = try? Data(contentsOf: Self.dateiURL),
           let gespeichert = try? JSONDecoder().decode(Daten.self, from: data) {
            daten = gespeichert
        } else {
            daten = Daten()
        }
    }

    var plan: TrainingPlan? { daten.plan }

    /// Der Drill so, wie er für den Spieler gerade eingestellt ist.
    func drill(_ id: String) -> DrillTemplate? {
        Katalog.drill(id)?.angepasst(an: zustand(id))
    }

    func zustand(_ id: String) -> DrillState {
        daten.zustaende[id] ?? DrillState()
    }

    func erledigt(_ item: PlanItem) -> Bool {
        daten.runs.contains { $0.planItemID == item.id }
    }

    func runs(fuer id: String) -> [DrillRun] {
        daten.runs.filter { $0.drillID == id }.sorted { $0.datum > $1.datum }
    }

    var alleRuns: [DrillRun] {
        daten.runs.sorted { $0.datum > $1.datum }
    }

    func neuerPlan() {
        daten.plan = Engine.planen(katalog: katalog, runs: daten.runs,
                                   folgeDrills: daten.folgeDrills, ohneGruppen: daten.ohneGruppen)
        daten.folgeDrills = []
        daten.ohneGruppen = []
    }

    /// Speichert einen fertigen Lauf, wertet ihn aus und merkt sich die Folgen.
    func abschliessen(_ run: DrillRun) -> Auswertung? {
        guard let basis = Katalog.drill(run.drillID) else { return nil }
        let auswertung = Engine.auswerten(run, drill: basis, zustand: zustand(run.drillID))
        var neu = daten
        neu.runs.append(run)
        neu.zustaende[run.drillID] = auswertung.zustand
        for item in auswertung.folgeDrills
        where !neu.folgeDrills.contains(where: { $0.drillID == item.drillID && $0.nurStep == item.nurStep }) {
            neu.folgeDrills.append(item)
        }
        neu.ohneGruppen.formUnion(auswertung.ohneGruppen)
        daten = neu
        return auswertung
    }

    func loeschen(_ run: DrillRun) {
        daten.runs.removeAll { $0.id == run.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(daten) {
            try? data.write(to: Self.dateiURL, options: .atomic)
        }
    }
}
