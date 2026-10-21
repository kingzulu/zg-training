import Foundation

/// Die fest eingebauten Drills (Stefans sechs Drills plus zwei Folge-Drills).
enum Katalog {
    static let alle: [DrillTemplate] = [
        dispersionGrid, ladderProtocol, pressureLoop,
        gateDrill, rollOutZonen, aroundTheClock,
        teeBox, puttGate,
    ]

    static func drill(_ id: String) -> DrillTemplate? {
        alle.first { $0.id == id }
    }

    static let dispersionGrid = DrillTemplate(
        id: "dispersion-grid",
        name: "Dispersion-Grid",
        kategorie: .eisen,
        beschreibung: "20 Bälle auf ein festes Ziel. Perfekt ± 5 m = 3 Punkte, Akzeptabel ± 10 m = 1 Punkt. Eisen-Leiter: Start mit Eisen 9, bei jedem Aufstieg ein Eisen länger.",
        steps: [Step(club: .eisen9, target: .fahne(meter: 120), baelle: 20, gruppe: .gruenAnspiel)],
        scoring: .zonen([
            Zone(name: "Perfekt", radiusMeter: 5, punkte: 3),
            Zone(name: "Akzeptabel", radiusMeter: 10, punkte: 1),
        ]),
        regeln: [
            Rule(wenn: .punkteMindestens(45), dann: [.schwerer],
                 grund: "Mindestens 45 Punkte: nächstes Mal ein Eisen länger."),
            Rule(wenn: .punkteUnter(35),
                 dann: [.leichter, .hinweis("Halbschwünge machen, Tee-Höhe prüfen und auf das Fehlerbild (Slice/Hook) achten.")],
                 grund: "Unter 35 Punkten: nächstes Mal ein Eisen zurück."),
        ],
        // Zieldistanzen sind Startwerte; bei Bedarf an die eigenen Längen anpassen.
        erschwerungen: [
            .eisen(.eisen8, meter: 135),
            .eisen(.eisen7, meter: 150),
            .eisen(.eisen6, meter: 160),
            .eisen(.eisen5, meter: 170),
        ],
        bereich: .gruenAnspiel
    )

    static let ladderProtocol = DrillTemplate(
        id: "ladder-protocol",
        name: "Ladder-Protocol",
        kategorie: .wedges,
        beschreibung: "Je 5 Bälle auf 40, 60 und 80 m mit fester Schwunglänge. Innerhalb 3 m = 1 Punkt.",
        steps: [
            Step(club: .lw, target: .fahne(meter: 40), schwung: .uhr9, baelle: 5, gruppe: .kurz),
            Step(club: .lw, target: .fahne(meter: 60), schwung: .uhr10, baelle: 5, gruppe: .kurz),
            Step(club: .lw, target: .fahne(meter: 80), schwung: .voll, baelle: 5, gruppe: .kurz),
        ],
        scoring: .toleranz(meter: 3),
        regeln: [
            Rule(wenn: .tendenzUeberall(.kurz), dann: [.schlaegerTausch(von: .lw, nach: .gw)],
                 grund: "Fast alle Fehler zu kurz: nächstes Mal Wedge 52° statt Lob Wedge."),
            Rule(wenn: .stepSchwach, dann: [.fokusSchwacherStep],
                 grund: "Eine Distanz streut deutlich stärker: Schwerpunkt-Drill genau dafür."),
        ],
        routineRegel: "Nicht schätzen: Jede Distanz mit der vorgegebenen Schwunglänge spielen.",
        bereich: .kurz
    )

    static let pressureLoop: DrillTemplate = {
        let bahn = [
            Step(club: .driver, target: .fairway, baelle: 1, gruppe: .lang),
            Step(club: .eisen6, target: .gruen, baelle: 1, gruppe: .gruenAnspiel),
            Step(club: .pw, target: .gruen, baelle: 1, gruppe: .kurz),
        ]
        let putt = Step(club: .putter, target: .putt(meter: 3, neigung: .gerade), baelle: 1,
                        gruppe: .putt, zaehltZurQuote: false)
        return DrillTemplate(
            id: "pressure-loop",
            name: "Pressure-Loop",
            kategorie: .platz,
            beschreibung: "Dreimal Driver, Eisen 6, Pitching Wedge, dann ein Putt. Ergebnis: Course-Readiness-Score.",
            steps: bahn + bahn + bahn + [putt],
            scoring: .zielErreicht,
            regeln: [
                Rule(wenn: .gruppeSchwach(.lang), dann: [.ohneGruppe(.kurz), .fokusDrill("tee-box")],
                     grund: "Die langen Schläge fallen ab: nächstes Mal Tee-Box-Fokus statt kurzer Schläge."),
                Rule(wenn: .gruppeSchwach(.gruenAnspiel), dann: [.fokusDrill("dispersion-grid")],
                     grund: "Der Weg vom Fairway aufs Grün fällt ab: Fokus auf Eisen-Treffer."),
            ],
            routineRegel: "Jeder Schlag mit voller Routine. Kein Warmschlagen mit demselben Schläger."
        )
    }()

    static let gateDrill = DrillTemplate(
        id: "gate-drill",
        name: "Flight- & Distance-Gate",
        kategorie: .pitchen,
        beschreibung: "10 Pitches über ein Tor 5 m vor dem Ziel. Zu flach = 0, über das Tor = 1, im 3-m-Kreis = 3 Punkte.",
        steps: [Step(club: .sw, target: .fahne(meter: 40), baelle: 10, gruppe: .kurz)],
        scoring: .stufen([.torUeberflogen, .imKreis(radiusMeter: 3)], punkte: [0, 1, 3]),
        regeln: [
            Rule(wenn: .punkteMindestens(20), dann: [.schwerer],
                 grund: "Mindestens 20 Punkte: Du beherrschst die Flugkurve, der Drill wird schwerer."),
            Rule(wenn: .punkteUnter(15),
                 dann: [.leichter, .hinweis("Halber Schwung, gleichmäßig beschleunigen: Ball zuerst, dann Boden.")],
                 grund: "Unter 15 Punkten: Technik vor Distanz."),
        ],
        erschwerungen: [.distanz(plusMeter: 20), .radius(faktor: 0.7)],
        bereich: .kurz
    )

    static let rollOutZonen = DrillTemplate(
        id: "roll-out-zonen",
        name: "Roll-Out-Zonen",
        kategorie: .chippen,
        beschreibung: "Je 4 Chips in Landezone A, B und C. Landezone getroffen = 1, zusätzlich im 1-m-Kreis ums Loch = 2 Punkte.",
        steps: ["A", "B", "C"].map { zone in
            Step(club: .eisen8, target: .landezone(zone), baelle: 4, gruppe: .kurz)
        },
        scoring: .stufen([.landezoneGetroffen(toleranzCm: 50), .imKreis(radiusMeter: 1)], punkte: [0, 1, 2]),
        regeln: [
            Rule(wenn: .tendenzNachStufe(1, .lang), dann: [.schlaegerTausch(von: .eisen8, nach: .pw)],
                 grund: "Die Bälle landen gut, rollen aber zu weit: nächstes Mal Pitching Wedge statt Eisen 8."),
        ],
        bereich: .kurz
    )

    static let aroundTheClock = DrillTemplate(
        id: "around-the-clock",
        name: "Around-the-Clock",
        kategorie: .putten,
        beschreibung: "4 Putts rund ums Loch. Ein Fehlputt setzt die Serie auf 0. Gezählt werden die Durchgänge bis zur 4er-Serie.",
        steps: [Step(club: .putter, target: .putt(meter: 1.5, neigung: .gerade), baelle: 4, gruppe: .putt)],
        scoring: .serie(laenge: 4),
        regeln: [
            Rule(wenn: .durchgaengeHoechstens(1), dann: [.schwerer],
                 grund: "Serie im ersten Durchgang: Der Drill wird schwerer."),
            Rule(wenn: .durchgaengeMehrAls(3), dann: [.fokusDrill("putt-gate")],
                 grund: "Mehr als 3 Durchgänge: Gate-Drill für eine gerade Puttlinie."),
        ],
        erschwerungen: [.puttDistanz(meter: 2), .puttBreak],
        maxDurchgaenge: 10,
        bereich: .putt
    )

    static let teeBox = DrillTemplate(
        id: "tee-box",
        name: "Tee-Box-Fokus",
        kategorie: .langesSpiel,
        beschreibung: "10 Drives mit voller Routine. Jeder Ball muss ein gedachtes Fairway treffen.",
        steps: [Step(club: .driver, target: .fairway, baelle: 10, gruppe: .lang)],
        scoring: .zielErreicht,
        routineRegel: "Vor jedem Ball die volle Routine.",
        bereich: .lang,
        imPlan: false
    )

    static let puttGate = DrillTemplate(
        id: "putt-gate",
        name: "Putt-Gate",
        kategorie: .putten,
        beschreibung: "Zwei Tees knapp breiter als der Putterkopf. 10 Putts aus 1,5 m, der Putter muss sauber durch das Tor.",
        steps: [Step(club: .putter, target: .putt(meter: 1.5, neigung: .gerade), baelle: 10, gruppe: .putt)],
        scoring: .zielErreicht,
        bereich: .putt,
        imPlan: false
    )
}
