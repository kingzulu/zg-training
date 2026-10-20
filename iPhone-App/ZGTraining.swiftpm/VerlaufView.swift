import SwiftUI

/// Alle bisherigen Ausführungen, neueste zuerst, mit Löschen und Export.
struct VerlaufView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State private var fragAllesLoeschen = false

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                        }
                    }
                    .onDelete { offsets in
                        let runs = store.alleRuns
                        for index in offsets { store.loeschen(runs[index]) }
                    }
                } footer: {
                    if !store.alleRuns.isEmpty {
                        Text("Zum Löschen nach links wischen oder oben auf „Bearbeiten“ tippen.")
                    }
                }

                Section {
                    Button("Alle Daten löschen", role: .destructive) {
                        fragAllesLoeschen = true
                    }
                } footer: {
                    Text("Löscht alle Trainings, den Plan und die Anpassungen der Drills.")
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
                ToolbarItemGroup(placement: .confirmationAction) {
                    EditButton()
                    Button("Fertig") { dismiss() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Wirklich alle Daten löschen?", isPresented: $fragAllesLoeschen,
                                titleVisibility: .visible) {
                Button("Alle Daten löschen", role: .destructive) { store.allesLoeschen() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Das lässt sich nicht rückgängig machen.")
            }
        }
    }
}
