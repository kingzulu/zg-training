import Foundation

// Das typisierte Drill-Modell: Jeder Drill ist aus festen Typen gebaut,
// damit fehlerhafte Drills (Putter auf 150 m, Zone ohne Radius) gar nicht
// erst entstehen können.

/// Alle Schläger, die in einem Drill vorkommen können.
enum Club: String, Codable, CaseIterable, Identifiable {
    case driver, holz, hybrid, eisen5, eisen6, eisen7, eisen8, eisen9, pw, gw, sw, lw, putter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .driver: return "Driver"
        case .holz: return "Holz"
        case .hybrid: return "Hybrid"
        case .eisen5: return "Eisen 5"
        case .eisen6: return "Eisen 6"
        case .eisen7: return "Eisen 7"
        case .eisen8: return "Eisen 8"
        case .eisen9: return "Eisen 9"
        case .pw: return "Pitching Wedge"
        case .gw: return "Wedge 52°"
        case .sw: return "Sand Wedge"
        case .lw: return "Lob Wedge"
        case .putter: return "Putter"
        }
    }
}

/// Feste Schwunglänge (linker Arm als Uhrzeiger).
enum SwingLength: String, Codable {
    case halb, uhr9, uhr10, voll

    var label: String {
        switch self {
        case .halb: return "halber Schwung"
        case .uhr9: return "9-Uhr-Schwung"
        case .uhr10: return "10-Uhr-Schwung"
        case .voll: return "voller Schwung"
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case langesSpiel, eisen, wedges, pitchen, chippen, putten, platz

    var label: String {
        switch self {
        case .langesSpiel: return "Langes Spiel"
        case .eisen: return "Eisen"
        case .wedges: return "Wedges"
        case .pitchen: return "Pitchen"
        case .chippen: return "Chippen"
        case .putten: return "Putten"
        case .platz: return "Platz-Simulation"
        }
    }

    var symbol: String {
        switch self {
        case .langesSpiel: return "arrow.up.forward"
        case .eisen: return "scope"
        case .wedges: return "ruler"
        case .pitchen: return "arrow.up.and.down.and.arrow.left.and.right"
        case .chippen: return "arrow.right.to.line"
        case .putten: return "circle.circle"
        case .platz: return "flag"
        }
    }
}

/// Bereich eines Schlags, z. B. für den Course-Readiness-Score.
enum ShotGroup: String, Codable, CaseIterable {
    case lang, gruenAnspiel, kurz, putt

    var label: String {
        switch self {
        case .lang: return "Lange Schläge"
        case .gruenAnspiel: return "Grün-Anspiel"
        case .kurz: return "Kurze Schläge"
        case .putt: return "Putten"
        }
    }
}

enum Slope: String, Codable {
    case gerade, leichterBreak
}

/// Wohin der Ball soll.
enum Target: Codable, Hashable {
    case fahne(meter: Double)
    case fairway
    case gruen
    case landezone(String)
    case putt(meter: Double, neigung: Slope)

    var label: String {
        switch self {
        case .fahne(let meter): return "Ziel auf \(Format.meter(meter))"
        case .fairway: return "Fairway treffen"
        case .gruen: return "Grün treffen"
        case .landezone(let name): return "Landezone \(name)"
        case .putt(let meter, let neigung):
            return "Putt aus \(Format.meter(meter))" + (neigung == .leichterBreak ? " mit Break" : "")
        }
    }
}

/// Eine einzelne Ja/Nein-Prüfung pro Ball.
enum Check: Codable, Hashable {
    case torUeberflogen
    case landezoneGetroffen(toleranzCm: Int)
    case imKreis(radiusMeter: Double)
    case eingelocht

    /// Text für die Taste, wenn der Ball an dieser Prüfung scheitert.
    var verfehltLabel: String {
        switch self {
        case .torUeberflogen: return "Zu flach (unter dem Tor)"
        case .landezoneGetroffen(let cm): return "Landezone verfehlt (± \(cm) cm)"
        case .imKreis(let radius): return "Außerhalb \(Format.meter(radius))"
        case .eingelocht: return "Nicht eingelocht"
        }
    }
}

struct Zone: Codable, Hashable {
    var name: String
    var radiusMeter: Double
    var punkte: Int
}

/// Wie ein Ball bewertet wird. Jeder Ball bekommt eine Stufe:
/// 0 = verfehlt, `maxLevel` = bestes Ergebnis.
enum Scoring: Codable, Hashable {
    /// Beste Zone zuerst, z. B. Perfekt ± 5 m = 3, Akzeptabel ± 10 m = 1.
    case zonen([Zone])
    case toleranz(meter: Double)
    case zielErreicht
    /// Prüfungen nacheinander; `punkte[n]` = Punkte für n bestandene Prüfungen.
    case stufen([Check], punkte: [Int])
    /// Serie ohne Fehler; ein Fehler startet den Durchgang neu.
    case serie(laenge: Int)

    var maxLevel: Int {
        switch self {
        case .zonen(let zonen): return zonen.count
        case .toleranz, .zielErreicht, .serie: return 1
        case .stufen(let checks, _): return checks.count
        }
    }

    func punkte(level: Int) -> Int {
        switch self {
        case .zonen(let zonen):
            guard level > 0 else { return 0 }
            return zonen[zonen.count - level].punkte
        case .toleranz, .zielErreicht, .serie:
            return level > 0 ? 1 : 0
        case .stufen(_, let punkte):
            return punkte[min(level, punkte.count - 1)]
        }
    }

    struct Option: Identifiable {
        let level: Int
        let label: String
        var id: Int { level }
    }

    /// Tasten für die Eingabe auf der Range, beste zuerst.
    var optionen: [Option] {
        switch self {
        case .zonen(let zonen):
            var result = zonen.enumerated().map { index, zone in
                Option(level: zonen.count - index,
                       label: "\(zone.name) ± \(Format.meter(zone.radiusMeter)) · \(zone.punkte) P")
            }
            result.append(Option(level: 0, label: "Daneben · 0 P"))
            return result
        case .toleranz(let meter):
            return [Option(level: 1, label: "Innerhalb \(Format.meter(meter))"),
                    Option(level: 0, label: "Daneben")]
        case .zielErreicht:
            return [Option(level: 1, label: "Ziel erreicht"),
                    Option(level: 0, label: "Verfehlt")]
        case .serie:
            return [Option(level: 1, label: "Eingelocht"),
                    Option(level: 0, label: "Daneben, Serie neu")]
        case .stufen(let checks, let punkte):
            return (0...checks.count).reversed().map { level -> Option in
                let text = level == checks.count ? "Im Ziel" : checks[level].verfehltLabel
                return Option(level: level, label: "\(text) · \(punkte[level]) P")
            }
        }
    }

    /// Kleinerer Radius bzw. engere Toleranz zum Hochstufen.
    func radiusSkaliert(_ faktor: Double) -> Scoring {
        switch self {
        case .zonen(let zonen):
            return .zonen(zonen.map { Zone(name: $0.name, radiusMeter: ($0.radiusMeter * faktor).rounded(), punkte: $0.punkte) })
        case .toleranz(let meter):
            return .toleranz(meter: max(1, (meter * faktor).rounded()))
        case .stufen(let checks, let punkte):
            let neu = checks.map { check -> Check in
                if case .imKreis(let radius) = check {
                    return .imKreis(radiusMeter: max(0.5, (radius * faktor * 2).rounded() / 2))
                }
                return check
            }
            return .stufen(neu, punkte: punkte)
        case .zielErreicht, .serie:
            return self
        }
    }
}

/// Eine Station im Drill, z. B. „5 Bälle Lob Wedge auf 60 m, 10-Uhr-Schwung“.
struct Step: Hashable {
    var club: Club
    var target: Target
    var schwung: SwingLength? = nil
    var baelle: Int
    var gruppe: ShotGroup? = nil
    var zaehltZurQuote = true
}

/// Wie ein Drill schwerer wird; die Liste im Drill gibt die Reihenfolge vor.
enum Erschwerung: Hashable {
    case radius(faktor: Double)
    case distanz(plusMeter: Double)
    case schlaeger(Club)
    /// Anderes Eisen mit passender Zieldistanz (Eisen-Leiter).
    case eisen(Club, meter: Double)
    case puttDistanz(meter: Double)
    case puttBreak
}

// MARK: - Ergebnisse

enum Richtung: String, Codable { case links, rechts }
enum Laenge: String, Codable { case kurz, lang }

/// Fehlerbild eines Balls, aus dem die Tendenz entsteht.
struct Miss: Codable, Hashable {
    var richtung: Richtung?
    var laenge: Laenge?

    var istLeer: Bool { richtung == nil && laenge == nil }
}

struct ShotResult: Codable, Hashable {
    var step: Int
    var durchgang: Int
    var level: Int
    var miss: Miss?
}

/// Eine Ausführung eines Drills.
struct DrillRun: Codable, Identifiable {
    var id = UUID()
    var drillID: String
    var datum: Date
    var stufe: Int
    var nurStep: Int?
    var planItemID: UUID?
    var ergebnisse: [ShotResult]
}

enum Format {
    static func meter(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value)) m" }
        return String(format: "%.1f m", value).replacingOccurrences(of: ".", with: ",")
    }
}
