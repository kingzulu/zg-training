# ZG-Training

iPhone-App von Zulu Golf ([zulugolf.de](https://www.zulugolf.de)) für strukturiertes Training auf der Range:
jeder Drill hat eine klare Bedingung, einen messbaren Score und Regeln für den nächsten Schritt.
Der Plan fürs nächste Training passt sich deiner Fehlertendenz an.

## Was drin ist (erste Version)

- **Sechs Drills:** Dispersion-Grid, Ladder-Protocol, Pressure-Loop, Flight- & Distance-Gate,
  Roll-Out-Zonen, Around-the-Clock, dazu die Folge-Drills Tee-Box-Fokus und Putt-Gate.
- **Erfassung pro Ball:** ein Tipp für das Ergebnis, bei Fehlern optional Richtung und Länge.
- **Score und Auswertung:** Punkte, Quote je Station und Bereich, Serien mit Neustart.
- **Regel-Engine:** Jeder Drill bringt seine eigenen Regeln mit (z. B. „ab 45 Punkten schwerer“).
  Der Tagesplan zeigt zu jedem Drill, warum er dran ist.
- **Daten:** bleiben auf dem iPhone (`zg-training.json`), Export über „Verlauf“.

Jev von TypeSafe AI kommt in Stufe 2 als Entscheider dazu; die Regeln bleiben das Sicherheitsnetz.

## Aufbau

| Datei | Inhalt |
| --- | --- |
| `Drill.swift` | Typen: Schläger, Ziele, Prüfungen, Bewertung, Ergebnisse |
| `DrillTemplate.swift` | Drill-Vorlage, Regeln, Erschwerungen, gespeicherter Drill-Zustand |
| `Katalog.swift` | Die eingebauten Drills |
| `Engine.swift` | Score-Berechnung, Regel-Auswertung, Tagesplan |
| `TrainingStore.swift` | Speichern und Laden |
| `ContentView.swift`, `RunView.swift`, `VerlaufView.swift`, `AboutView.swift`, `Brand.swift` | Oberfläche im ZG-Design |

## Bauen

Ordner `iPhone-App/ZGTraining.swiftpm` in Xcode (oder Swift Playgrounds) öffnen und auf dem iPhone starten.
Mindestens iOS 16.
