import SwiftUI

/// Alle bisherigen Ausführungen, neueste zuerst, mit Export der Daten.
struct VerlaufView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.alleRuns.isEmpty {
                    Text("Noch keine Trainings. Starte einen Drill auf der Startseite.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.alleRuns) { run in
                    if let drill = Katalog.drill(run.drillID) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(drill.name).font(.headline)
                            Text(Score.berechnen(run, drill: drill).anzeige)
                            Text(run.datum.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button("Löschen", role: .destructive) { store.loeschen(run) }
                        }
                    }
                }
            }
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ShareLink(item: TrainingStore.dateiURL) {
                        Label("Exportieren", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
