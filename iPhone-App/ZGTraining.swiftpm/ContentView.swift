import SwiftUI

/// Startseite: der Plan für heute und alle Drills.
struct ContentView: View {
    @EnvironmentObject private var store: TrainingStore
    @State private var showAbout = false
    @State private var showVerlauf = false

    var body: some View {
        NavigationStack {
            List {
                heuteSection
                Section("Alle Drills") {
                    ForEach(store.katalog) { vorlage in
                        if let drill = store.drill(vorlage.id) {
                            NavigationLink {
                                RunView(drill: drill, planItem: nil)
                            } label: {
                                DrillRow(drill: drill, letzter: store.runs(fuer: drill.id).first)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .modifier(BrandToolbar(title: "Training", rightLabel: "Verlauf",
                                   onBrand: { showAbout = true }, onRight: { showVerlauf = true }))
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showVerlauf) {
                VerlaufView().environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private var heuteSection: some View {
        Section {
            if let plan = store.plan {
                ForEach(plan.items) { item in
                    if let drill = store.drill(item.drillID) {
                        NavigationLink {
                            RunView(drill: drill, planItem: item)
                        } label: {
                            PlanRow(drill: drill, item: item, erledigt: store.erledigt(item))
                        }
                    }
                }
            }
            Button {
                store.neuerPlan()
            } label: {
                Label(store.plan == nil ? "Training planen" : "Neuen Plan erstellen",
                      systemImage: "wand.and.stars")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Heute")
        } footer: {
            if let notiz = store.plan?.notiz {
                Text(notiz)
            } else if store.plan == nil {
                Text("Die App stellt dein Training aus deinen letzten Ergebnissen zusammen und sagt dir jeweils, warum.")
            }
        }
    }
}

private struct PlanRow: View {
    let drill: DrillTemplate
    let item: PlanItem
    let erledigt: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: erledigt ? "checkmark.circle.fill" : drill.kategorie.symbol)
                .font(.title3)
                .foregroundColor(erledigt ? Color.green : Color.zuluBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(drill.name).font(.headline)
                if let step = item.nurStep, drill.steps.indices.contains(step) {
                    Text("Schwerpunkt: \(drill.steps[step].target.label)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.zuluBlue)
                }
                Text(item.grund)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DrillRow: View {
    let drill: DrillTemplate
    let letzter: DrillRun?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: drill.kategorie.symbol)
                .font(.title3)
                .foregroundColor(.zuluBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(drill.name).font(.headline)
                Text(drill.kategorie.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let letzter, let basis = Katalog.drill(drill.id) {
                    Text("Zuletzt: " + Score.berechnen(letzter, drill: basis).anzeige)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
