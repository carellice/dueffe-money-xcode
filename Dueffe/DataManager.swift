import Foundation
import SwiftUI

// MARK: - SOSTITUIRE SalvadanaiModel IN DataManager.swift
struct SalvadanaiModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: String // "objective", "glass", "infinite"
    var currentAmount: Double
    var targetAmount: Double
    var targetDate: Date?
    var monthlyRefill: Double
    var color: String
    var category: String // NUOVO: Categoria del salvadanaio
    var createdAt: Date
    var isInfinite: Bool
}

// MARK: - AGGIORNARE TransactionModel IN DataManager.swift
struct TransactionModel: Identifiable, Codable {
    let id = UUID()
    var amount: Double
    var descr: String
    var category: String
    var type: String // "expense", "income", "salary", "transfer", "distribution"
    var date: Date
    var accountName: String
    var salvadanaiName: String?
    
    // AGGIORNATO: Proprietà computate per gestire il nuovo tipo "distribution"
    var isTransfer: Bool {
        return type == "transfer"
    }
    
    var isDistribution: Bool {
        return type == "distribution"
    }
    
    var isExpense: Bool {
        return type == "expense"
    }
    
    var isIncome: Bool {
        return type == "income" || type == "salary"
    }
    
    var displayColor: Color {
        switch type {
        case "expense": return .red
        case "salary": return .blue
        case "transfer": return .orange
        case "transfer_salvadanai": return .green
        case "distribution": return .purple
        default: return .green
        }
    }
    
    var displayIcon: String {
        switch type {
        case "expense": return "minus.circle.fill"
        case "salary": return "banknote.fill"
        case "transfer": return "arrow.left.arrow.right.circle.fill"
        case "transfer_salvadanai": return "arrow.left.arrow.right.circle.fill"
        case "distribution": return "arrow.branch.circle.fill"
        default: return "plus.circle.fill"
        }
    }
    
    var displayDescription: String {
        if isTransfer {
            if let salvadanaiName = salvadanaiName {
                return "\(descr): \(accountName) → \(salvadanaiName)"
            }
        } else if isDistribution {
            if let salvadanaiName = salvadanaiName {
                return "\(descr) → \(salvadanaiName)"
            }
        }
        return descr
    }
}

struct AccountModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var balance: Double
    var createdAt: Date
}

// MARK: - Distribution Suggestion Model
struct DistributionSuggestion {
    let salvadanaiName: String
    let suggestedAmount: Double
    let reason: String
    let priority: Priority
    
    enum Priority: Int, CaseIterable {
        case high = 3
        case medium = 2
        case low = 1
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .high: return "exclamationmark.triangle.fill"
            case .medium: return "clock.fill"
            case .low: return "info.circle.fill"
            }
        }
    }
}

// MARK: - Distribution Validation
struct DistributionValidation {
    let isValid: Bool
    let message: String
    
    var color: Color {
        isValid ? .green : .red
    }
    
    var icon: String {
        isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
}

// MARK: - Data Manager con persistenza (CLASSE PRINCIPALE AGGIORNATA)
class DataManager: ObservableObject {
    @Published var salvadanai: [SalvadanaiModel] = [] {
        didSet { saveSalvadanai() }
    }
    @Published var transactions: [TransactionModel] = [] {
        didSet { saveTransactions() }
    }
    @Published var accounts: [AccountModel] = [] {
        didSet { saveAccounts() }
    }
    @Published var customExpenseCategories: [String] = [] {
        didSet { saveCategories() }
    }
    @Published var customIncomeCategories: [String] = [] {
        didSet { saveCategories() }
    }
    
    // NUOVO: Categorie personalizzate per salvadanai
    @Published var customSalvadanaiCategories: [String] = [] {
        didSet { saveSalvadanaiCategories() }
    }
    
    // Categorie predefinite (base)
    let defaultExpenseCategories = [
        "🍕 Cibo", "🚗 Trasporti", "🎬 Intrattenimento",
        "👕 Abbigliamento", "🏥 Salute", "📚 Educazione",
        "🏠 Casa", "💰 Altro"
    ]
    
    let defaultIncomeCategories = [
        "💼 Stipendio", "💸 Freelance", "🎁 Regalo",
        "💰 Investimenti", "📈 Bonus", "🔄 Altro"
    ]
    
    // NUOVO: Categorie predefinite per i salvadanai (RIDOTTE)
    let defaultSalvadanaiCategories = [
        "🏠 Casa",
        "✈️ Viaggi",
        "🚗 Trasporti",
        "🎓 Educazione",
        "💊 Salute",
        "🎮 Hobby",
        "🔧 Emergenze",
        "🔄 Altro"
    ]
    
    // Categorie complete (predefinite + personalizzate)
    var expenseCategories: [String] {
        return defaultExpenseCategories + customExpenseCategories.sorted()
    }
    
    var incomeCategories: [String] {
        return defaultIncomeCategories + customIncomeCategories.sorted()
    }
    
    // NUOVO: Tutte le categorie salvadanai (predefinite + personalizzate)
    var allSalvadanaiCategories: [String] {
        return defaultSalvadanaiCategories + customSalvadanaiCategories.sorted()
    }
    
    // Colori predefiniti per i salvadanai
    let salvadanaiColors = [
        "blue", "green", "orange", "purple",
        "pink", "red", "yellow", "indigo"
    ]
    
    // Chiavi per UserDefaults
    private let salvadanaiKey = "SavedSalvadanai"
    private let transactionsKey = "SavedTransactions"
    private let accountsKey = "SavedAccounts"
    private let customExpenseCategoriesKey = "CustomExpenseCategories"
    private let customIncomeCategoriesKey = "CustomIncomeCategories"
    private let customSalvadanaiCategoriesKey = "CustomSalvadanaiCategories" // NUOVO
    
    init() {
        loadAllData()
    }
    
    // MARK: - Persistence Methods
    private func loadAllData() {
        loadSalvadanai()
        loadTransactions()
        loadAccounts()
        loadStoredCategories()
        loadSalvadanaiCategories() // NUOVO
    }
    
    // MARK: - Salvadanai Persistence
    private func saveSalvadanai() {
        if let encoded = try? JSONEncoder().encode(salvadanai) {
            UserDefaults.standard.set(encoded, forKey: salvadanaiKey)
        }
    }
    
    private func loadSalvadanai() {
        if let data = UserDefaults.standard.data(forKey: salvadanaiKey),
           let decoded = try? JSONDecoder().decode([SalvadanaiModel].self, from: data) {
            salvadanai = decoded
        }
    }
    
    // MARK: - Transactions Persistence
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([TransactionModel].self, from: data) {
            transactions = decoded
        }
    }
    
    // MARK: - Accounts Persistence
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }
    
    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([AccountModel].self, from: data) {
            accounts = decoded
        }
    }
    
    // MARK: - Categories Persistence
    private func saveCategories() {
        UserDefaults.standard.set(customExpenseCategories, forKey: customExpenseCategoriesKey)
        UserDefaults.standard.set(customIncomeCategories, forKey: customIncomeCategoriesKey)
    }
    
    private func loadStoredCategories() {
        customExpenseCategories = UserDefaults.standard.stringArray(forKey: customExpenseCategoriesKey) ?? []
        customIncomeCategories = UserDefaults.standard.stringArray(forKey: customIncomeCategoriesKey) ?? []
    }
    
    // MARK: - NUOVO: Salvadanai Categories Persistence
    private func saveSalvadanaiCategories() {
        UserDefaults.standard.set(customSalvadanaiCategories, forKey: customSalvadanaiCategoriesKey)
    }
    
    private func loadSalvadanaiCategories() {
        customSalvadanaiCategories = UserDefaults.standard.stringArray(forKey: customSalvadanaiCategoriesKey) ?? []
    }
    
    // MARK: - Categories Management
    func addExpenseCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !expenseCategories.contains(trimmedCategory) else { return }
        
        customExpenseCategories.append(trimmedCategory)
    }
    
    func addIncomeCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !incomeCategories.contains(trimmedCategory) else { return }
        
        customIncomeCategories.append(trimmedCategory)
    }
    
    func deleteExpenseCategory(_ category: String) {
        guard !defaultExpenseCategories.contains(category) else { return }
        customExpenseCategories.removeAll { $0 == category }
    }
    
    func deleteIncomeCategory(_ category: String) {
        guard !defaultIncomeCategories.contains(category) else { return }
        customIncomeCategories.removeAll { $0 == category }
    }
    
    // MARK: - NUOVO: Salvadanai Categories Management
    func addSalvadanaiCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !allSalvadanaiCategories.contains(trimmedCategory) else { return }
        
        customSalvadanaiCategories.append(trimmedCategory)
    }
    
    func deleteSalvadanaiCategory(_ category: String) {
        guard !defaultSalvadanaiCategories.contains(category) else { return }
        customSalvadanaiCategories.removeAll { $0 == category }
    }
    
    // MODIFICATO: addSalvadanaio - con categoria
    func addSalvadanaio(name: String, type: String, targetAmount: Double = 0, targetDate: Date? = nil, monthlyRefill: Double = 0, color: String, category: String, isInfinite: Bool = false) {
        let newSalvadanaio = SalvadanaiModel(
            name: name,
            type: type,
            currentAmount: 0.0,
            targetAmount: isInfinite ? 0 : targetAmount,
            targetDate: isInfinite ? nil : targetDate,
            monthlyRefill: monthlyRefill,
            color: color,
            category: category, // NUOVO
            createdAt: Date(),
            isInfinite: isInfinite
        )
        salvadanai.append(newSalvadanaio)
    }
    
    func updateSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        if let index = salvadanai.firstIndex(where: { $0.id == salvadanaio.id }) {
            salvadanai[index] = salvadanaio
        }
    }
    
    func deleteSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        salvadanai.removeAll { $0.id == salvadanaio.id }
    }
    
    // NUOVO: Metodi per gestione categorie salvadanai
    func getSalvadanaiByCategory(_ category: String) -> [SalvadanaiModel] {
        if category == "Tutti" {
            return salvadanai
        }
        return salvadanai.filter { $0.category == category }
    }
    
    var usedSalvadanaiCategories: [String] {
        let used = Set(salvadanai.map { $0.category })
        return Array(used).sorted()
    }
    
    func addTransaction(amount: Double, descr: String, category: String, type: String, accountName: String? = nil, salvadanaiName: String? = nil) {
        let newTransaction = TransactionModel(
            amount: amount,
            descr: descr,
            category: category,
            type: type,
            date: Date(),
            accountName: accountName ?? "",
            salvadanaiName: salvadanaiName
        )
        transactions.append(newTransaction)
        
        if type == "expense" {
            if let salvadanaiName = salvadanaiName {
                updateSalvadanaiBalance(name: salvadanaiName, amount: -amount)
            }
            
            if let accountName = accountName {
                updateAccountBalance(accountName: accountName, amount: -amount)
            }
        } else {
            if let accountName = accountName {
                updateAccountBalance(accountName: accountName, amount: amount)
            }
        }
    }

    func deleteTransaction(_ transaction: TransactionModel) {
        transactions.removeAll { $0.id == transaction.id }
        
        if transaction.type == "expense" {
            if let salvadanaiName = transaction.salvadanaiName {
                updateSalvadanaiBalance(name: salvadanaiName, amount: transaction.amount)
            }
            
            if !transaction.accountName.isEmpty {
                updateAccountBalance(accountName: transaction.accountName, amount: transaction.amount)
            }
        } else if transaction.type == "transfer" {
            if !transaction.accountName.isEmpty {
                updateAccountBalance(accountName: transaction.accountName, amount: transaction.amount)
            }
            if let toAccount = transaction.salvadanaiName {
                updateAccountBalance(accountName: toAccount, amount: -transaction.amount)
            }
        } else if transaction.type == "transfer_salvadanai" {
            if !transaction.accountName.isEmpty {
                updateSalvadanaiBalance(name: transaction.accountName, amount: transaction.amount)
            }
            if let toSalvadanaio = transaction.salvadanaiName {
                updateSalvadanaiBalance(name: toSalvadanaio, amount: -transaction.amount)
            }
        } else {
            if !transaction.accountName.isEmpty {
                updateAccountBalance(accountName: transaction.accountName, amount: -transaction.amount)
            }
        }
    }
    
    // MARK: - Account Methods
    func addAccount(name: String, initialBalance: Double = 0) {
        let newAccount = AccountModel(
            name: name,
            balance: initialBalance,
            createdAt: Date()
        )
        accounts.append(newAccount)
    }
    
    func updateAccountBalance(accountName: String, amount: Double) {
        if let index = accounts.firstIndex(where: { $0.name == accountName }) {
            accounts[index].balance += amount
        }
    }
    
    func deleteAccount(_ account: AccountModel) {
        accounts.removeAll { $0.id == account.id }
    }
    
    // MARK: - Helper Methods
    private func updateSalvadanaiBalance(name: String, amount: Double) {
        if let index = salvadanai.firstIndex(where: { $0.name == name }) {
            salvadanai[index].currentAmount += amount
        }
    }
    
    // MARK: - DISTRIBUZIONE STIPENDI
    
    func distributeIncomeWithCustomAmounts(amount: Double, salvadanaiAmounts: [String: Double], accountName: String, transactionType: String = "salary") {
        let descriptionText = transactionType == "salary" ? "Stipendio" : "Entrata"
        let categoryText = transactionType == "salary" ? "💼 Stipendio" : "💸 Entrata"
        
        addTransaction(
            amount: amount,
            descr: descriptionText,
            category: categoryText,
            type: transactionType,
            accountName: accountName
        )
        
        for (salvadanaiName, customAmount) in salvadanaiAmounts {
            if let index = salvadanai.firstIndex(where: { $0.name == salvadanaiName }) {
                if customAmount > 0 {
                    salvadanai[index].currentAmount += customAmount
                    
                    addDistributionTransaction(
                        amount: customAmount,
                        fromAccount: accountName,
                        toSalvadanaio: salvadanaiName,
                        description: "Distribuzione \(descriptionText.lowercased())"
                    )
                }
            }
        }
    }
    
    func distributeIncomeAutomatically(amount: Double, accountName: String, transactionType: String = "salary") {
        let automaticDistribution = calculateAutomaticDistribution(totalAmount: amount)
        
        distributeIncomeWithCustomAmounts(
            amount: amount,
            salvadanaiAmounts: automaticDistribution,
            accountName: accountName,
            transactionType: transactionType
        )
    }
    
    private func addDistributionTransaction(amount: Double, fromAccount: String, toSalvadanaio: String, description: String) {
        let distributionTransaction = TransactionModel(
            amount: amount,
            descr: description,
            category: "🔄 Distribuzione",
            type: "distribution",
            date: Date(),
            accountName: fromAccount,
            salvadanaiName: toSalvadanaio
        )
        transactions.append(distributionTransaction)
    }
    
    func calculateAutomaticDistribution(totalAmount: Double) -> [String: Double] {
        var distribution: [String: Double] = [:]
        var remainingAmount = totalAmount
        
        let glassSalvadanai = salvadanai.filter { $0.type == "glass" }
            .sorted { $0.currentAmount < $1.currentAmount }
        
        for salvadanaio in glassSalvadanai {
            let needed = max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
            if needed > 0 && remainingAmount > 0 {
                let toAdd = min(needed, remainingAmount)
                distribution[salvadanaio.name] = toAdd
                remainingAmount -= toAdd
            }
        }
        
        let objectiveSalvadanai = salvadanai.filter {
            $0.type == "objective" && !$0.isInfinite && $0.targetDate != nil
        }.sorted {
            ($0.targetDate ?? Date.distantFuture) < ($1.targetDate ?? Date.distantFuture)
        }
        
        for salvadanaio in objectiveSalvadanai {
            if remainingAmount <= 0 { break }
            
            let needed = max(0, salvadanaio.targetAmount - salvadanaio.currentAmount)
            if needed > 0 {
                let daysRemaining = Calendar.current.dateComponents([.day],
                    from: Date(),
                    to: salvadanaio.targetDate ?? Date.distantFuture).day ?? Int.max
                
                let urgencyMultiplier: Double
                if daysRemaining <= 30 {
                    urgencyMultiplier = 1.5
                } else if daysRemaining <= 90 {
                    urgencyMultiplier = 1.2
                } else {
                    urgencyMultiplier = 1.0
                }
                
                let baseAllocation = min(150, needed)
                let allocation = min(baseAllocation * urgencyMultiplier, remainingAmount)
                
                if allocation > 0 {
                    distribution[salvadanaio.name] = (distribution[salvadanaio.name] ?? 0) + allocation
                    remainingAmount -= allocation
                }
            }
        }
        
        let infiniteSalvadanai = salvadanai.filter { $0.type == "objective" && $0.isInfinite }
        if !infiniteSalvadanai.isEmpty && remainingAmount > 0 {
            let perInfinite = remainingAmount / Double(infiniteSalvadanai.count)
            for salvadanaio in infiniteSalvadanai {
                distribution[salvadanaio.name] = (distribution[salvadanaio.name] ?? 0) + perInfinite
            }
            remainingAmount = 0
        }
        
        if remainingAmount > 0 && !distribution.isEmpty {
            let perSelected = remainingAmount / Double(distribution.count)
            for key in distribution.keys {
                distribution[key] = (distribution[key] ?? 0) + perSelected
            }
        }
        
        return distribution
    }
    
    func distributeIncomeEqually(amount: Double, toSalvadanai selectedSalvadanai: [String], accountName: String, transactionType: String = "salary") {
        guard !selectedSalvadanai.isEmpty else { return }
        
        let perSalvadanaio = amount / Double(selectedSalvadanai.count)
        let equalDistribution = Dictionary(uniqueKeysWithValues: selectedSalvadanai.map { ($0, perSalvadanaio) })
        
        distributeIncomeWithCustomAmounts(
            amount: amount,
            salvadanaiAmounts: equalDistribution,
            accountName: accountName,
            transactionType: transactionType
        )
    }
    
    func getDistributionSuggestions(amount: Double) -> [DistributionSuggestion] {
        var suggestions: [DistributionSuggestion] = []
        
        let glassSalvadanai = salvadanai.filter { $0.type == "glass" }
        for salvadanaio in glassSalvadanai {
            let needed = max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
            if needed > 0 {
                suggestions.append(DistributionSuggestion(
                    salvadanaiName: salvadanaio.name,
                    suggestedAmount: min(needed, amount),
                    reason: "Ricarica Glass necessaria",
                    priority: .high
                ))
            }
        }
        
        let urgentObjectives = salvadanai.filter {
            $0.type == "objective" && !$0.isInfinite && $0.targetDate != nil
        }.filter { salvadanaio in
            guard let targetDate = salvadanaio.targetDate else { return false }
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
            return daysRemaining <= 60 && salvadanaio.currentAmount < salvadanaio.targetAmount
        }
        
        for salvadanaio in urgentObjectives {
            let needed = salvadanaio.targetAmount - salvadanaio.currentAmount
            let daysRemaining = Calendar.current.dateComponents([.day],
                from: Date(),
                to: salvadanaio.targetDate ?? Date.distantFuture).day ?? 0
            
            suggestions.append(DistributionSuggestion(
                salvadanaiName: salvadanaio.name,
                suggestedAmount: min(needed, amount * 0.3),
                reason: "Scadenza in \(daysRemaining) giorni",
                priority: daysRemaining <= 30 ? .high : .medium
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Computed Properties per DataManager
extension DataManager {
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalSavings: Double {
        salvadanai.reduce(0) { $0 + $1.currentAmount }
    }
    
    var availableBalance: Double {
        let positiveSavings = salvadanai.filter { $0.currentAmount > 0 }.reduce(0) { $0 + $1.currentAmount }
        return totalBalance + positiveSavings
    }
    
    var recentTransactions: [TransactionModel] {
        transactions.sorted { $0.date > $1.date }
    }
}
