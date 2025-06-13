import Foundation
import SwiftUI

// MARK: - Formatters globali
import Foundation

import Foundation

extension Double {
    var italianCurrency: String {
        // Determina se mostrare i decimali
        let hasDecimals = self.truncatingRemainder(dividingBy: 1) != 0
        
        // Usa sempre il valore assoluto per la formattazione
        let absValue = abs(self)
        
        // Converti in stringa con o senza decimali
        let numberString: String
        if hasDecimals {
            numberString = String(format: "%.2f", absValue)
        } else {
            numberString = String(format: "%.0f", absValue)
        }
        
        // Separa parte intera e decimale
        let components = numberString.components(separatedBy: ".")
        let integerPart = components[0]
        let decimalPart = components.count > 1 ? components[1] : nil
        
        // Aggiungi i separatori delle migliaia alla parte intera
        let formattedInteger = addThousandsSeparator(to: integerPart)
        
        // Costruisci il risultato finale
        let formattedNumber: String
        if let decimals = decimalPart, hasDecimals {
            formattedNumber = "\(formattedInteger),\(decimals) €"
        } else {
            formattedNumber = "\(formattedInteger) €"
        }
        
        // Aggiungi il segno meno se necessario
        return self < 0 ? "-\(formattedNumber)" : formattedNumber
    }
    
    private func addThousandsSeparator(to numberString: String) -> String {
        let reversed = String(numberString.reversed())
        var result = ""
        
        for (index, character) in reversed.enumerated() {
            if index > 0 && index % 3 == 0 {
                result += "."
            }
            result += String(character)
        }
        
        return String(result.reversed())
    }
}


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

// SOSTITUIRE AccountModel nel file DataManager.swift
struct AccountModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var balance: Double
    var createdAt: Date
    var isClosed: Bool = false // NUOVO: Indica se il conto è chiuso
    
    // NUOVO: Computed property per verificare se il conto può essere chiuso
    var canBeClosed: Bool {
        return !isClosed
    }
    
    // NUOVO: Computed property per verificare se il conto ha saldo diverso da zero
    var hasNonZeroBalance: Bool {
        return abs(balance) > 0.01 // Tolleranza per errori di arrotondamento
    }
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
        return sortCategoriesAlphabetically(defaultExpenseCategories + customExpenseCategories)
    }
    
    var incomeCategories: [String] {
        return sortCategoriesAlphabetically(defaultIncomeCategories + customIncomeCategories)
    }
    
    // NUOVO: Tutte le categorie salvadanai (predefinite + personalizzate)
    var allSalvadanaiCategories: [String] {
        return sortCategoriesAlphabetically(defaultSalvadanaiCategories + customSalvadanaiCategories)
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
        return sortCategoriesAlphabetically(Array(used))
    }
    
    /// Salvadanai ordinati alfabeticamente per nome
    var sortedSalvadanai: [SalvadanaiModel] {
        return sortedSalvadanai(self.salvadanai)
    }

    /// Account ordinati alfabeticamente per nome
    var sortedAccounts: [AccountModel] {
        return sortedAccounts(self.accounts)
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
        // RIMUOVI IL VECCHIO CODICE E SOSTITUISCI CON QUESTO:
        
        // Per entrate e stipendi, non fare nulla qui - sarà gestito dalla vista di distribuzione inversa
        if (transaction.type == "income" || transaction.type == "salary") && !salvadanai.isEmpty {
            // Non eliminare automaticamente - l'utente deve scegliere la distribuzione inversa
            return
        }
        
        // Per le altre transazioni, comportamento normale
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
            // Per entrate/stipendi senza salvadanai, rimuovi solo dal conto
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
    
    /// Filtra e ordina le categorie spese
    func filteredAndSortedExpenseCategories(searchText: String) -> (custom: [String], predefined: [String]) {
        let customFiltered = searchText.isEmpty ?
            customExpenseCategories :
            customExpenseCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        let predefinedFiltered = searchText.isEmpty ?
            defaultExpenseCategories :
            defaultExpenseCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        return (
            custom: sortCategoriesAlphabetically(customFiltered),
            predefined: sortCategoriesAlphabetically(predefinedFiltered)
        )
    }

    /// Filtra e ordina le categorie entrate
    func filteredAndSortedIncomeCategories(searchText: String) -> (custom: [String], predefined: [String]) {
        let customFiltered = searchText.isEmpty ?
            customIncomeCategories :
            customIncomeCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        let predefinedFiltered = searchText.isEmpty ?
            defaultIncomeCategories :
            defaultIncomeCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        return (
            custom: sortCategoriesAlphabetically(customFiltered),
            predefined: sortCategoriesAlphabetically(predefinedFiltered)
        )
    }

    /// Filtra e ordina le categorie salvadanai
    func filteredAndSortedSalvadanaiCategories(searchText: String) -> (custom: [String], predefined: [String]) {
        let customFiltered = searchText.isEmpty ?
            customSalvadanaiCategories :
            customSalvadanaiCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        let predefinedFiltered = searchText.isEmpty ?
            defaultSalvadanaiCategories :
            defaultSalvadanaiCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        return (
            custom: sortCategoriesAlphabetically(customFiltered),
            predefined: sortCategoriesAlphabetically(predefinedFiltered)
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
}

// MARK: - NUOVO: Metodo per aggiornare il nome di un conto e tutte le transazioni associate
extension DataManager {
    
    /// Aggiorna il nome di un conto e tutte le transazioni associate
    /// - Parameters:
    ///   - account: L'account da aggiornare
    ///   - newName: Il nuovo nome per l'account
    /// Aggiorna il nome di un conto e tutte le transazioni associate
    func updateAccountName(_ accountId: UUID, oldName: String, newName: String) {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty else { return }
        
        print("🔄 Aggiornamento nome conto: '\(oldName)' -> '\(trimmedNewName)'")
        
        // 1. Aggiorna l'account
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].name = trimmedNewName
            print("✅ Account aggiornato")
        }
        
        // 2. Aggiorna tutte le transazioni associate
        var updatedCount = 0
        
        for index in transactions.indices {
            var updated = false
            
            // Aggiorna il campo accountName
            if transactions[index].accountName == oldName {
                transactions[index].accountName = trimmedNewName
                updated = true
            }
            
            // Aggiorna il campo salvadanaiName per i trasferimenti tra conti
            if transactions[index].type == "transfer" &&
               transactions[index].salvadanaiName == oldName {
                transactions[index].salvadanaiName = trimmedNewName
                updated = true
            }
            
            if updated {
                updatedCount += 1
            }
        }
        
        print("✅ Aggiornate \(updatedCount) transazioni")
        
        // Force save to make sure data persists
        DispatchQueue.main.async {
            // Il didSet si occuperà di salvare automaticamente
            self.objectWillChange.send()
        }
    }
    
    /// Aggiorna il nome dell'account in tutte le transazioni che lo referenziano
    /// - Parameters:
    ///   - oldName: Il vecchio nome dell'account
    ///   - newName: Il nuovo nome dell'account
    private func updateTransactionsAccountName(from oldName: String, to newName: String) {
        for index in transactions.indices {
            // Aggiorna il campo accountName
            if transactions[index].accountName == oldName {
                transactions[index].accountName = newName
            }
            
            // Aggiorna il campo salvadanaiName per i trasferimenti tra conti
            // (dove il conto di destinazione è memorizzato in salvadanaiName)
            if transactions[index].type == "transfer" &&
               transactions[index].salvadanaiName == oldName {
                transactions[index].salvadanaiName = newName
            }
        }
    }
}

// MARK: - Export/Import Data
struct ExportData: Codable {
    let accounts: [AccountModel]
    let salvadanai: [SalvadanaiModel]
    let transactions: [TransactionModel]
    let customExpenseCategories: [String]
    let customIncomeCategories: [String]
    let customSalvadanaiCategories: [String]
    let exportDate: Date
    let appVersion: String
    
    init(dataManager: DataManager) {
        self.accounts = dataManager.accounts
        self.salvadanai = dataManager.salvadanai
        self.transactions = dataManager.transactions
        self.customExpenseCategories = dataManager.customExpenseCategories
        self.customIncomeCategories = dataManager.customIncomeCategories
        self.customSalvadanaiCategories = dataManager.customSalvadanaiCategories
        self.exportDate = Date()
        self.appVersion = "1.0"
    }
}

// MARK: - Funzioni di Ordinamento Centralizzate
extension DataManager {
    
    /// Ordina le categorie alfabeticamente, ignorando gli emoji iniziali
    private func sortCategoriesAlphabetically(_ categories: [String]) -> [String] {
        return categories.sorted { category1, category2 in
            let name1 = extractCategoryName(from: category1)
            let name2 = extractCategoryName(from: category2)
            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }
    }
    
    /// Estrae il nome della categoria rimuovendo l'emoji iniziale se presente
    private func extractCategoryName(from category: String) -> String {
        if let firstChar = category.first, firstChar.isEmoji {
            return String(category.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return category
    }
    
    /// Ordina un array di salvadanai per nome alfabeticamente
    func sortedSalvadanai(_ salvadanai: [SalvadanaiModel]) -> [SalvadanaiModel] {
        return salvadanai.sorted { salvadanaio1, salvadanaio2 in
            salvadanaio1.name.localizedCaseInsensitiveCompare(salvadanaio2.name) == .orderedAscending
        }
    }
    
    /// Ordina un array di account per nome alfabeticamente
    func sortedAccounts(_ accounts: [AccountModel]) -> [AccountModel] {
        return accounts.sorted { account1, account2 in
            account1.name.localizedCaseInsensitiveCompare(account2.name) == .orderedAscending
        }
    }
}

// MARK: - Account Closure Methods
extension DataManager {
    
    /// Chiude un conto trasferendo il saldo ad un altro conto
    /// - Parameters:
    ///   - accountToClose: Il conto da chiudere
    ///   - destinationAccount: Il conto di destinazione per il saldo
    /// - Returns: True se la chiusura è avvenuta con successo
    func closeAccount(_ accountToClose: AccountModel, transferingBalanceTo destinationAccount: AccountModel) -> Bool {
        guard let closeIndex = accounts.firstIndex(where: { $0.id == accountToClose.id }),
              let destIndex = accounts.firstIndex(where: { $0.id == destinationAccount.id }) else {
            print("❌ Errore: Impossibile trovare i conti")
            return false
        }
        
        guard accounts[closeIndex].canBeClosed else {
            print("❌ Errore: Il conto è già chiuso")
            return false
        }
        
        guard accountToClose.id != destinationAccount.id else {
            print("❌ Errore: Non puoi trasferire il saldo allo stesso conto")
            return false
        }
        
        print("🔒 Chiusura conto '\(accountToClose.name)'")
        print("  - Saldo da trasferire: \(accountToClose.balance.italianCurrency)")
        print("  - Verso: '\(destinationAccount.name)'")
        
        // 1. Trasferisci il saldo se diverso da zero
        if accountToClose.hasNonZeroBalance {
            let transferAmount = accounts[closeIndex].balance
            
            // Sottrai dal conto da chiudere
            accounts[closeIndex].balance = 0.0
            
            // Aggiungi al conto di destinazione
            accounts[destIndex].balance += transferAmount
            
            // Registra la transazione di trasferimento
            let transferDescription = "Trasferimento per chiusura conto '\(accountToClose.name)'"
            let transferTransaction = TransactionModel(
                amount: abs(transferAmount),
                descr: transferDescription,
                category: "🔒 Chiusura Conto",
                type: "transfer",
                date: Date(),
                accountName: accountToClose.name,
                salvadanaiName: destinationAccount.name
            )
            
            transactions.append(transferTransaction)
            print("  ✅ Saldo trasferito: \(transferAmount.italianCurrency)")
        }
        
        // 2. Chiudi il conto
        accounts[closeIndex].isClosed = true
        print("  ✅ Conto chiuso")
        
        // 3. Marca tutte le transazioni associate come "locked"
        let relatedTransactionsCount = markTransactionsAsLocked(for: accountToClose.name)
        print("  ✅ Bloccate \(relatedTransactionsCount) transazioni")
        
        return true
    }
    
    /// Chiude un conto senza saldo (solo se il saldo è zero)
    /// - Parameter accountToClose: Il conto da chiudere
    /// - Returns: True se la chiusura è avvenuta con successo
    func closeAccountWithZeroBalance(_ accountToClose: AccountModel) -> Bool {
        guard let index = accounts.firstIndex(where: { $0.id == accountToClose.id }) else {
            print("❌ Errore: Impossibile trovare il conto")
            return false
        }
        
        guard accounts[index].canBeClosed else {
            print("❌ Errore: Il conto è già chiuso")
            return false
        }
        
        guard !accounts[index].hasNonZeroBalance else {
            print("❌ Errore: Il conto ha un saldo diverso da zero")
            return false
        }
        
        print("🔒 Chiusura conto con saldo zero '\(accountToClose.name)'")
        
        // Chiudi il conto
        accounts[index].isClosed = true
        
        // Marca tutte le transazioni associate come "locked"
        let relatedTransactionsCount = markTransactionsAsLocked(for: accountToClose.name)
        print("  ✅ Conto chiuso")
        print("  ✅ Bloccate \(relatedTransactionsCount) transazioni")
        
        return true
    }
    
    /// Riapre un conto chiuso
    /// - Parameter account: Il conto da riaprire
    /// - Returns: True se la riapertura è avvenuta con successo
    func reopenAccount(_ account: AccountModel) -> Bool {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else {
            print("❌ Errore: Impossibile trovare il conto")
            return false
        }
        
        guard accounts[index].isClosed else {
            print("❌ Errore: Il conto non è chiuso")
            return false
        }
        
        print("🔓 Riapertura conto '\(account.name)'")
        
        // Riapri il conto
        accounts[index].isClosed = false
        
        // Sblocca tutte le transazioni associate
        let unlockedTransactionsCount = unmarkTransactionsAsLocked(for: account.name)
        print("  ✅ Conto riaperto")
        print("  ✅ Sbloccate \(unlockedTransactionsCount) transazioni")
        
        return true
    }
    
    /// Marca le transazioni di un conto come "bloccate" (non eliminabili)
    /// - Parameter accountName: Nome del conto
    /// - Returns: Numero di transazioni bloccate
    private func markTransactionsAsLocked(for accountName: String) -> Int {
        var count = 0
        for index in transactions.indices {
            if transactions[index].accountName == accountName ||
               (transactions[index].type == "transfer" && transactions[index].salvadanaiName == accountName) {
                // Per ora non abbiamo un campo isLocked nel TransactionModel
                // La logica di blocco sarà gestita dalla UI controllando se l'account è chiuso
                count += 1
            }
        }
        return count
    }
    
    /// Sblocca le transazioni di un conto
    /// - Parameter accountName: Nome del conto
    /// - Returns: Numero di transazioni sbloccate
    private func unmarkTransactionsAsLocked(for accountName: String) -> Int {
        var count = 0
        for index in transactions.indices {
            if transactions[index].accountName == accountName ||
               (transactions[index].type == "transfer" && transactions[index].salvadanaiName == accountName) {
                count += 1
            }
        }
        return count
    }
    
    /// Verifica se una transazione è bloccata (associata a un conto chiuso)
    /// - Parameter transaction: La transazione da verificare
    /// - Returns: True se la transazione è bloccata
    func isTransactionLocked(_ transaction: TransactionModel) -> Bool {
        // Verifica se il conto principale è chiuso
        if let account = accounts.first(where: { $0.name == transaction.accountName }) {
            if account.isClosed {
                return true
            }
        }
        
        // Verifica se il conto di destinazione (per i trasferimenti) è chiuso
        if transaction.type == "transfer",
           let destinationAccount = accounts.first(where: { $0.name == transaction.salvadanaiName }) {
            if destinationAccount.isClosed {
                return true
            }
        }
        
        return false
    }
    
    /// Ottiene tutti i conti aperti (non chiusi)
    var openAccounts: [AccountModel] {
        return accounts.filter { !$0.isClosed }
    }
    
    /// Ordina un array di account aperti per nome alfabeticamente
    var sortedOpenAccounts: [AccountModel] {
        return sortedAccounts(openAccounts)
    }

    /// Ottiene tutti i conti chiusi
    var closedAccounts: [AccountModel] {
        return accounts.filter { $0.isClosed }
    }
}

extension DataManager {
    
    // MARK: - Export Data
    func exportData() -> Data? {
        let exportData = ExportData(dataManager: self)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            return try encoder.encode(exportData)
        } catch {
            print("Errore nell'esportazione: \(error)")
            return nil
        }
    }
    
    func getExportFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yy_HH-mm"
        let dateString = formatter.string(from: Date())
        return "dueffe_money\(dateString).json"
    }
    
    // MARK: - Import Data
    func importData(from data: Data) -> ImportResult {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let importedData = try decoder.decode(ExportData.self, from: data)
            
            // Validazione dei dati
            if importedData.accounts.isEmpty {
                return ImportResult(success: false, message: "Il file di backup non contiene conti validi")
            }
            
            // Backup dei dati attuali (opzionale)
            let currentBackup = ExportData(dataManager: self)
            
            // Importa i dati
            withAnimation {
                self.accounts = importedData.accounts
                self.salvadanai = importedData.salvadanai
                self.transactions = importedData.transactions
                self.customExpenseCategories = importedData.customExpenseCategories
                self.customIncomeCategories = importedData.customIncomeCategories
                self.customSalvadanaiCategories = importedData.customSalvadanaiCategories
            }
            
            // Reset onboarding flags poiché ora abbiamo dati completi
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            UserDefaults.standard.set(true, forKey: "hasCreatedFirstSalvadanaio")
            UserDefaults.standard.set(true, forKey: "hasAddedInitialBalance")
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let exportDateString = formatter.string(from: importedData.exportDate)
            
            return ImportResult(
                success: true,
                message: "Dati importati con successo!\n\nBackup del: \(exportDateString)\nConti: \(importedData.accounts.count)\nSalvadanai: \(importedData.salvadanai.count)\nTransazioni: \(importedData.transactions.count)"
            )
            
        } catch {
            return ImportResult(success: false, message: "Errore nell'importazione: file non valido o corrotto")
        }
    }
    
    // MARK: - NUOVO: Metodo per controllare se una transazione richiede distribuzione inversa
    func transactionRequiresReverseDistribution(_ transaction: TransactionModel) -> Bool {
        return (transaction.type == "income" || transaction.type == "salary") && !salvadanai.isEmpty
    }

    // MARK: - NUOVO: Metodo per eliminazione transazione con distribuzione inversa
    func deleteTransactionWithReverseDistribution(_ transaction: TransactionModel, salvadanaiAmounts: [String: Double]) {
        // 1. Rimuovi dai salvadanai le somme specificate
        for (salvadanaiName, amount) in salvadanaiAmounts {
            if let index = salvadanai.firstIndex(where: { $0.name == salvadanaiName }) {
                salvadanai[index].currentAmount -= amount
            }
        }
        
        // 2. Rimuovi dal conto (già fatto dalla logica esistente, ma per sicurezza)
        if !transaction.accountName.isEmpty {
            updateAccountBalance(accountName: transaction.accountName, amount: -transaction.amount)
        }
        
        // 3. Trova e rimuovi le transazioni di distribuzione correlate
        let relatedDistributionTransactions = transactions.filter {
            $0.type == "distribution" &&
            $0.date.timeIntervalSince(transaction.date) < 300 && // Entro 5 minuti dalla transazione originale
            $0.accountName == transaction.accountName
        }
        
        // Rimuovi le distribuzioni correlate
        for distributionTransaction in relatedDistributionTransactions {
            transactions.removeAll { $0.id == distributionTransaction.id }
        }
        
        // 4. Rimuovi la transazione originale
        transactions.removeAll { $0.id == transaction.id }
    }
    
    /// Aggiorna il nome di un salvadanaio e tutte le transazioni associate
    /// - Parameters:
    ///   - salvadanaiId: L'ID del salvadanaio da aggiornare
    ///   - oldName: Il vecchio nome del salvadanaio
    ///   - newName: Il nuovo nome per il salvadanaio
    func updateSalvadanaiName(_ salvadanaiId: UUID, oldName: String, newName: String) {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty else { return }
        
        print("🔄 Aggiornamento nome salvadanaio: '\(oldName)' -> '\(trimmedNewName)'")
        
        // 1. Aggiorna il salvadanaio
        if let index = salvadanai.firstIndex(where: { $0.id == salvadanaiId }) {
            salvadanai[index].name = trimmedNewName
            print("✅ Salvadanaio aggiornato")
        }
        
        // 2. Aggiorna tutte le transazioni associate
        var updatedCount = 0
        
        for index in transactions.indices {
            var updated = false
            
            // Aggiorna il campo salvadanaiName per spese, trasferimenti salvadanai e distribuzioni
            if transactions[index].salvadanaiName == oldName {
                transactions[index].salvadanaiName = trimmedNewName
                updated = true
            }
            
            // Aggiorna il campo accountName per i trasferimenti tra salvadanai (dove il salvadanaio di origine è in accountName)
            if transactions[index].type == "transfer_salvadanai" &&
               transactions[index].accountName == oldName {
                transactions[index].accountName = trimmedNewName
                updated = true
            }
            
            if updated {
                updatedCount += 1
            }
        }
        
        print("✅ Aggiornate \(updatedCount) transazioni")
        
        // Force save to make sure data persists
        DispatchQueue.main.async {
            // Il didSet si occuperà di salvare automaticamente
            self.objectWillChange.send()
        }
    }
}

struct ImportResult {
    let success: Bool
    let message: String
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value >= 0x238d || unicodeScalars.count > 1)
    }
}

