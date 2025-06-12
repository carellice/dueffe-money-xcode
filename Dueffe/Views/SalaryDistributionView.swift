import SwiftUI

// MARK: - Salary Distribution View (CORRETTA)
struct SalaryDistributionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let amount: Double
    let descr: String
    let transactionType: String
    let selectedAccount: String
    let onComplete: () -> Void // NUOVO: Callback per chiudere il sheet padre
    
    @State private var selectedSalvadanai: Set<String> = []
    @State private var customAmounts: [String: Double] = [:]
    @State private var distributionMode: DistributionMode = .equal
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum DistributionMode: String, CaseIterable {
        case equal = "Equa"
        case custom = "Personalizzata"
        case automatic = "Automatica"
        
        var icon: String {
            switch self {
            case .equal: return "equal.circle.fill"
            case .custom: return "slider.horizontal.3"
            case .automatic: return "sparkles" // CAMBIATO: icona che esiste sicuramente
            }
        }
        
        var description: String {
            switch self {
            case .equal: return "Dividi l'importo in parti uguali"
            case .custom: return "Specifica importi personalizzati"
            case .automatic: return "Distribuzione intelligente"
            }
        }
    }
    
    private var totalDistributed: Double {
        switch distributionMode {
        case .equal:
            return selectedSalvadanai.isEmpty ? 0 : amount
        case .custom:
            return customAmounts.values.reduce(0, +)
        case .automatic:
            return calculateAutomaticDistribution().values.reduce(0, +)
        }
    }
    
    private var remainingAmount: Double {
        amount - totalDistributed
    }
    
    private var isDistributionValid: Bool {
        !selectedSalvadanai.isEmpty && abs(remainingAmount) < 0.01
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con riepilogo
                    SalaryDistributionHeaderView(
                        amount: amount,
                        totalDistributed: totalDistributed,
                        remainingAmount: remainingAmount,
                        descr: descr,
                        accountName: selectedAccount
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    Form {
                        // Modalità di distribuzione
                        Section {
                            ForEach(DistributionMode.allCases, id: \.self) { mode in
                                DistributionModeRow(
                                    mode: mode,
                                    isSelected: distributionMode == mode,
                                    action: {
                                        withAnimation(.spring()) {
                                            distributionMode = mode
                                            if mode == .automatic {
                                                setupAutomaticDistribution()
                                            }
                                        }
                                    }
                                )
                            }
                        } header: {
                            SectionHeader(icon: "gearshape.fill", title: "Modalità di Distribuzione")
                        }
                        
                        // Lista salvadanai
                        Section {
                            if dataManager.salvadanai.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Nessun salvadanaio disponibile")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 8)
                            } else {
                                ForEach(dataManager.salvadanai, id: \.id) { salvadanaio in
                                    SalvadanaiDistributionRow(
                                        salvadanaio: salvadanaio,
                                        isSelected: selectedSalvadanai.contains(salvadanaio.name),
                                        distributionMode: distributionMode,
                                        equalAmount: selectedSalvadanai.isEmpty ? 0 : amount / Double(selectedSalvadanai.count),
                                        customAmount: Binding(
                                            get: { customAmounts[salvadanaio.name] ?? 0 },
                                            set: { customAmounts[salvadanaio.name] = $0 }
                                        ),
                                        automaticAmount: calculateAutomaticDistribution()[salvadanaio.name] ?? 0,
                                        onToggle: {
                                            toggleSalvadanaio(salvadanaio.name)
                                        }
                                    )
                                }
                            }
                        } header: {
                            SectionHeader(icon: "banknote.fill", title: "Seleziona Salvadanai")
                        } footer: {
                            if distributionMode == .custom && !selectedSalvadanai.isEmpty {
                                CustomDistributionFooterView(
                                    totalDistributed: totalDistributed,
                                    remainingAmount: remainingAmount,
                                    amount: amount
                                )
                            } else if distributionMode == .automatic {
                                AutomaticDistributionFooterView()
                            }
                        }
                        
                        // Azioni rapide per distribuzione personalizzata
                        if distributionMode == .custom && !selectedSalvadanai.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    CustomDistributionQuickActionsView(
                                        selectedSalvadanai: selectedSalvadanai,
                                        totalAmount: amount,
                                        customAmounts: $customAmounts
                                    )
                                }
                            } header: {
                                SectionHeader(icon: "bolt.fill", title: "Azioni Rapide")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Distribuisci \(transactionType == "salary" ? "Stipendio" : "Entrata")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Distribuisci") {
                        distributeAmount()
                    }
                    .disabled(!isDistributionValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isDistributionValid ? .green : .secondary)
                }
            }
        }
        .onAppear {
            setupInitialSelection()
        }
        .alert("Distribuzione", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupInitialSelection() {
        // Seleziona automaticamente tutti i salvadanai se ce ne sono pochi
        if dataManager.salvadanai.count <= 3 {
            selectedSalvadanai = Set(dataManager.salvadanai.map(\.name))
        }
        
        // Setup distribuzione automatica se selezionata
        if distributionMode == .automatic {
            setupAutomaticDistribution()
        }
    }
    
    private func toggleSalvadanaio(_ name: String) {
        if selectedSalvadanai.contains(name) {
            selectedSalvadanai.remove(name)
            customAmounts[name] = 0
        } else {
            selectedSalvadanai.insert(name)
            if distributionMode == .custom {
                customAmounts[name] = 0
            }
        }
        
        // Ricalcola distribuzione automatica se necessario
        if distributionMode == .automatic {
            setupAutomaticDistribution()
        }
    }
    
    private func setupAutomaticDistribution() {
        let automaticDistribution = calculateAutomaticDistribution()
        selectedSalvadanai = Set(automaticDistribution.keys)
    }
    
    private func calculateAutomaticDistribution() -> [String: Double] {
        return dataManager.calculateAutomaticDistribution(totalAmount: amount)
    }
    
    private func distributeAmount() {
        guard isDistributionValid else {
            alertMessage = "La distribuzione non è valida. Assicurati che l'importo totale sia distribuito completamente."
            showingAlert = true
            return
        }
        
        let finalAmounts: [String: Double]
        
        switch distributionMode {
        case .equal:
            let perSalvadanaio = amount / Double(selectedSalvadanai.count)
            finalAmounts = Dictionary(uniqueKeysWithValues: selectedSalvadanai.map { ($0, perSalvadanaio) })
        case .custom:
            finalAmounts = customAmounts.filter { selectedSalvadanai.contains($0.key) && $0.value > 0 }
        case .automatic:
            finalAmounts = calculateAutomaticDistribution()
        }
        
        // Effettua la distribuzione tramite DataManager
        dataManager.distributeIncomeWithCustomAmounts(
            amount: amount,
            salvadanaiAmounts: finalAmounts,
            accountName: selectedAccount,
            transactionType: transactionType
        )
        
        // NUOVO: Chiama il callback per chiudere il sheet padre e poi chiudi questo
        onComplete()
        dismiss()
    }
}

// MARK: - Il resto delle viste rimane uguale...
// (SalaryDistributionHeaderView, DistributionStatCard, etc.)

// MARK: - Salary Distribution Header
struct SalaryDistributionHeaderView: View {
    let amount: Double
    let totalDistributed: Double
    let remainingAmount: Double
    let descr: String
    let accountName: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Importo principale
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text(amount.italianCurrency)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(descr)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.blue)
                    Text("su \(accountName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            // Statistiche distribuzione
            HStack(spacing: 20) {
                DistributionStatCard(
                    title: "Distribuito",
                    amount: totalDistributed,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                DistributionStatCard(
                    title: "Rimanente",
                    amount: remainingAmount,
                    icon: remainingAmount > 0.01 ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                    color: remainingAmount > 0.01 ? .orange : .green
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Distribution Stat Card
struct DistributionStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(amount.italianCurrency)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Distribution Mode Row
struct DistributionModeRow: View {
    let mode: SalaryDistributionView.DistributionMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              LinearGradient(gradient: Gradient(colors: [.blue, .green]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    
                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Salvadanai Distribution Row
struct SalvadanaiDistributionRow: View {
    let salvadanaio: SalvadanaiModel
    let isSelected: Bool
    let distributionMode: SalaryDistributionView.DistributionMode
    let equalAmount: Double
    let customAmount: Binding<Double>
    let automaticAmount: Double
    let onToggle: () -> Void
    
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .blue
        }
    }
    
    private var displayAmount: Double {
        switch distributionMode {
        case .equal:
            return isSelected ? equalAmount : 0
        case .custom:
            return customAmount.wrappedValue
        case .automatic:
            return automaticAmount
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Icona salvadanaio
                Circle()
                    .fill(getColor(from: salvadanaio.color))
                    .frame(width: 12, height: 12)
                
                // Info salvadanaio
                VStack(alignment: .leading, spacing: 4) {
                    Text(salvadanaio.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    HStack {
                        Text("Attuale: \(salvadanaio.currentAmount.italianCurrency)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                            Text("• Obiettivo: \(salvadanaio.targetAmount.italianCurrency)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if salvadanaio.type == "glass" {
                            Text("• Glass: \(salvadanaio.monthlyRefill.italianCurrency)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Campo importo per distribuzione personalizzata
                if distributionMode == .custom && isSelected {
                    HStack {
                        Text("")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("0", value: customAmount, format: .currency(code: "EUR"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                    }
                } else if isSelected && displayAmount > 0 {
                    // Mostra importo per altre modalità
                    Text("\(displayAmount.italianCurrency)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, 12)
            
            // Info aggiuntiva per distribuzione automatica
            if distributionMode == .automatic && automaticAmount > 0 && isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.leading, 60)
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if salvadanaio.type == "glass" {
                                let needed = max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
                                if needed > 0 {
                                    Text("Ricarica necessaria: \(needed.italianCurrency)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            } else if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                                let needed = max(0, salvadanaio.targetAmount - salvadanaio.currentAmount)
                                if needed > 0 {
                                    Text("Mancano: \(needed.italianCurrency)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Saldo dopo: \((salvadanaio.currentAmount + automaticAmount).italianCurrency)")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.leading, 60)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

// MARK: - Custom Distribution Footer
struct CustomDistributionFooterView: View {
    let totalDistributed: Double
    let remainingAmount: Double
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Distribuito: \(totalDistributed.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Rimanente: \(remainingAmount.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(remainingAmount > 0.01 ? .orange : .green)
                    .fontWeight(.medium)
            }
            
            if abs(remainingAmount) > 0.01 {
                Text("⚠️ Distribuzione incompleta. Assicurati che l'importo totale sia distribuito completamente.")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text("✅ Distribuzione completa!")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Automatic Distribution Footer
struct AutomaticDistributionFooterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("La distribuzione automatica prioritizza:")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("1. 🥤 Ricarica Glass salvadanai")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("2. 🎯 Obiettivi con scadenza vicina")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("3. ♾️ Distribuzione equa tra salvadanai infiniti")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Custom Distribution Quick Actions
struct CustomDistributionQuickActionsView: View {
    let selectedSalvadanai: Set<String>
    let totalAmount: Double
    @Binding var customAmounts: [String: Double]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Distribuzione equa
                Button(action: {
                    let equalAmount = totalAmount / Double(selectedSalvadanai.count)
                    for name in selectedSalvadanai {
                        customAmounts[name] = equalAmount
                    }
                }) {
                    HStack {
                        Image(systemName: "equal.circle.fill")
                        Text("Equa")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
                
                // Reset
                Button(action: {
                    for name in selectedSalvadanai {
                        customAmounts[name] = 0
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Reset")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
    }
}
