import SwiftUI

// MARK: - Distribution Suggestions View
struct DistributionSuggestionsView: View {
    @EnvironmentObject var dataManager: DataManager
    let amount: Double
    @Binding var selectedSalvadanai: Set<String>
    @Binding var customAmounts: [String: Double]
    let onApplySuggestion: (DistributionSuggestion) -> Void
    
    private var suggestions: [DistributionSuggestion] {
        dataManager.getDistributionSuggestions(amount: amount)
    }
    
    var body: some View {
        if !suggestions.isEmpty {
            Section {
                VStack(spacing: 12) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.salvadanaiName) { index, suggestion in
                        DistributionSuggestionRow(
                            suggestion: suggestion,
                            isFirst: index == 0,
                            onApply: {
                                onApplySuggestion(suggestion)
                            }
                        )
                    }
                }
            } header: {
                SectionHeader(icon: "lightbulb.fill", title: "Suggerimenti Intelligenti")
            } footer: {
                Text("Suggerimenti basati su priorità, scadenze e necessità dei tuoi salvadanai")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Distribution Suggestion Row
struct DistributionSuggestionRow: View {
    let suggestion: DistributionSuggestion
    let isFirst: Bool
    let onApply: () -> Void
    @State private var animateCard = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icona priorità
            ZStack {
                Circle()
                    .fill(suggestion.priority.color.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(suggestion.priority.color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: suggestion.priority.icon)
                    .font(.caption)
                    .foregroundColor(suggestion.priority.color)
            }
            
            // Contenuto suggerimento
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.salvadanaiName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Suggerito:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("€\(String(format: "%.2f", suggestion.suggestedAmount))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(suggestion.priority.color)
                }
            }
            
            Spacer()
            
            // Bottone applica
            Button(action: onApply) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("Applica")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(suggestion.priority.color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(suggestion.priority.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(suggestion.priority.color)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(suggestion.priority.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: suggestion.priority.color.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateCard ? 1.0 : 0.95)
        .opacity(animateCard ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(isFirst ? 0 : 0.1), value: animateCard)
        .onAppear {
            animateCard = true
        }
    }
}

// MARK: - Smart Distribution Helper
struct SmartDistributionHelper {
    let dataManager: DataManager
    
    func getOptimalDistribution(amount: Double) -> [String: Double] {
        return dataManager.calculateAutomaticDistribution(totalAmount: amount)
    }
    
    func getDistributionScore(distribution: [String: Double]) -> Double {
        var score: Double = 0
        
        for (salvadanaiName, amount) in distribution {
            guard let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) else { continue }
            
            // Punteggio basato sul tipo di salvadanaio
            if salvadanaio.type == "glass" {
                let fillPercentage = min(1.0, (salvadanaio.currentAmount + amount) / salvadanaio.monthlyRefill)
                score += fillPercentage * 100 // Bonus per riempire Glass
            } else if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                let progressToTarget = min(1.0, (salvadanaio.currentAmount + amount) / salvadanaio.targetAmount)
                score += progressToTarget * 80 // Bonus per progresso verso obiettivo
                
                // Bonus extra per obiettivi con scadenza vicina
                if let targetDate = salvadanaio.targetDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? Int.max
                    if daysRemaining <= 30 {
                        score += 50 // Bonus urgenza alta
                    } else if daysRemaining <= 90 {
                        score += 25 // Bonus urgenza media
                    }
                }
            } else if salvadanaio.type == "objective" && salvadanaio.isInfinite {
                score += 30 // Punteggio base per obiettivi infiniti
            }
        }
        
        return score
    }
    
    func validateDistribution(distribution: [String: Double], totalAmount: Double) -> DistributionValidation {
        let totalDistributed = distribution.values.reduce(0, +)
        let difference = abs(totalAmount - totalDistributed)
        
        if difference < 0.01 {
            return DistributionValidation(isValid: true, message: "Distribuzione perfetta!")
        } else if totalDistributed > totalAmount {
            return DistributionValidation(
                isValid: false,
                message: "Distribuzione eccessiva di €\(String(format: "%.2f", difference))"
            )
        } else {
            return DistributionValidation(
                isValid: false,
                message: "Rimangono €\(String(format: "%.2f", difference)) da distribuire"
            )
        }
    }
}

// MARK: - Distribution Summary Card
struct DistributionSummaryCard: View {
    let totalAmount: Double
    let distribution: [String: Double]
    let validation: DistributionValidation
    @EnvironmentObject var dataManager: DataManager
    
    private var distributionItems: [(String, Double)] {
        distribution.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("Riepilogo Distribuzione")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Validazione
            HStack {
                Image(systemName: validation.icon)
                    .foregroundColor(validation.color)
                Text(validation.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(validation.color)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(validation.color.opacity(0.1))
            )
            
            // Lista distribuzione
            if !distributionItems.isEmpty {
                VStack(spacing: 8) {
                    ForEach(distributionItems, id: \.0) { salvadanaiName, amount in
                        DistributionSummaryRow(
                            salvadanaiName: salvadanaiName,
                            amount: amount,
                            percentage: amount / totalAmount,
                            salvadanaio: dataManager.salvadanai.first { $0.name == salvadanaiName }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Distribution Summary Row
struct DistributionSummaryRow: View {
    let salvadanaiName: String
    let amount: Double
    let percentage: Double
    let salvadanaio: SalvadanaiModel?
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicatore colore salvadanaio
            if let salvadanaio = salvadanaio {
                Circle()
                    .fill(getColor(from: salvadanaio.color))
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 12)
            }
            
            // Nome salvadanaio
            Text(salvadanaiName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Percentuale
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            // Importo
            Text("€\(String(format: "%.2f", amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Quick Distribution Actions
struct QuickDistributionActions: View {
    let totalAmount: Double
    let availableSalvadanai: [SalvadanaiModel]
    @Binding var selectedSalvadanai: Set<String>
    @Binding var customAmounts: [String: Double]
    @Binding var distributionMode: SalaryDistributionView.DistributionMode
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Azioni Rapide")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Bottoni azione
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Tutti i Salvadanai",
                    subtitle: "Seleziona tutti",
                    icon: "checkmark.circle.fill",
                    color: .blue,
                    action: {
                        selectedSalvadanai = Set(availableSalvadanai.map(\.name))
                        if distributionMode == .custom {
                            let equalAmount = totalAmount / Double(selectedSalvadanai.count)
                            for name in selectedSalvadanai {
                                customAmounts[name] = equalAmount
                            }
                        }
                    }
                )
                
                QuickActionButton(
                    title: "Solo Glass",
                    subtitle: "Ricarica Glass",
                    icon: "cup.and.saucer.fill",
                    color: .cyan,
                    action: {
                        let glassSalvadanai = availableSalvadanai.filter { $0.type == "glass" }
                        selectedSalvadanai = Set(glassSalvadanai.map(\.name))
                        
                        if distributionMode == .custom {
                            let equalAmount = totalAmount / Double(selectedSalvadanai.count)
                            for salvadanaio in glassSalvadanai {
                                customAmounts[salvadanaio.name] = min(equalAmount,
                                    max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount))
                            }
                        }
                    }
                )
                
                QuickActionButton(
                    title: "Obiettivi Urgenti",
                    subtitle: "Scadenze vicine",
                    icon: "clock.fill",
                    color: .orange,
                    action: {
                        let urgentObjectives = availableSalvadanai.filter { salvadanaio in
                            guard salvadanaio.type == "objective" && !salvadanaio.isInfinite,
                                  let targetDate = salvadanaio.targetDate else { return false }
                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? Int.max
                            return daysRemaining <= 60
                        }
                        selectedSalvadanai = Set(urgentObjectives.map(\.name))
                        
                        if distributionMode == .custom {
                            let equalAmount = totalAmount / Double(selectedSalvadanai.count)
                            for salvadanaio in urgentObjectives {
                                customAmounts[salvadanaio.name] = equalAmount
                            }
                        }
                    }
                )
                
                QuickActionButton(
                    title: "Reset",
                    subtitle: "Azzera tutto",
                    icon: "arrow.counterclockwise.circle.fill",
                    color: .red,
                    action: {
                        selectedSalvadanai.removeAll()
                        customAmounts.removeAll()
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Action eseguita nel button action
        }
    }
}
