import Foundation

/// Wann eine Drill-Regel greift.
enum RuleCondition: Hashable {
    case punkteMindestens(Int)
    case punkteUnter(Int)
    /// Die meisten Fehler gehen in diese Länge (z. B. alle zu kurz).
    case tendenzUeberall(Laenge)
    /// Eine Station ist deutlich schwächer als die anderen.
    case stepSchwach
    /// Eine Gruppe (z. B. lange Schläge) ist deutlich schwächer als der Rest.
    case gruppeSchwach(ShotGroup)
    /// Bälle, die genau `stufe` Prüfungen bestanden haben, gehen meist in diese Länge.
    case tendenzNachStufe(Int, Laenge)
    case durchgaengeHoechstens(Int)
    case durchgaengeMehrAls(Int)
}

/// Was eine Drill-Regel für das nächste Training bewirkt.
enum RuleAction: Hashable {
    case schwerer
    case leichter
    case schlaegerTausch(von: Club, nach: Club)
    case fokusDrill(String)
    case fokusSchwacherStep
    case ohneGruppe(ShotGroup)
    case hinweis(String)
}

struct Rule: Hashable {
    var wenn: RuleCondition
    var dann: [RuleAction]
    var grund: String
}

/// Eine Drill-Vorlage: Stationen, Bewertung, Regeln für den nächsten Schritt.
struct DrillTemplate: Identifiable {
    let id: String
    var name: String
    var kategorie: Category
    var beschreibung: String
    var steps: [Step]
    var scoring: Scoring
    var regeln: [Rule] = []
    var erschwerungen: [Erschwerung] = []
    var routineRegel: String? = nil
    /// Nur bei Serien: Abbruch nach so vielen Durchgängen.
    var maxDurchgaenge: Int? = nil
    /// Bereich des ganzen Drills; `nil` bei gemischten Sequenzen.
    var bereich: ShotGroup? = nil
    /// `false` für Drills, die nur als Folge-Drill eingeplant werden.
    var imPlan = true

    var istSerie: Bool {
        if case .serie = scoring { return true }
        return false
    }

    /// Der Drill mit den Erschwerungen und Schlägerwechseln des Spielers.
    func angepasst(an zustand: DrillState) -> DrillTemplate {
        var drill = self
        for erschwerung in erschwerungen.prefix(zustand.stufe) {
            drill.anwenden(erschwerung)
        }
        for index in drill.steps.indices {
            if let neu = zustand.tausch[drill.steps[index].club.rawValue] {
                drill.steps[index].club = neu
            }
        }
        return drill
    }

    private mutating func anwenden(_ erschwerung: Erschwerung) {
        switch erschwerung {
        case .radius(let faktor):
            scoring = scoring.radiusSkaliert(faktor)
        case .distanz(let plus):
            for index in steps.indices {
                if case .fahne(let meter) = steps[index].target {
                    steps[index].target = .fahne(meter: meter + plus)
                }
            }
        case .schlaeger(let club):
            for index in steps.indices { steps[index].club = club }
        case .puttDistanz(let neu):
            for index in steps.indices {
                if case .putt(_, let neigung) = steps[index].target {
                    steps[index].target = .putt(meter: neu, neigung: neigung)
                }
            }
        case .puttBreak:
            for index in steps.indices {
                if case .putt(let meter, _) = steps[index].target {
                    steps[index].target = .putt(meter: meter, neigung: .leichterBreak)
                }
            }
        }
    }
}

/// Was die App sich pro Drill merkt: Schwierigkeit, Schlägerwechsel, Hinweis.
struct DrillState: Codable, Hashable {
    var stufe = 0
    /// Schläger-Rohwert → Ersatz-Schläger.
    var tausch: [String: Club] = [:]
    var hinweis: String?
}
