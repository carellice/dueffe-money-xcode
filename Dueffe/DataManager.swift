import Foundation
import SwiftUI

// MARK: - Data Models (con Codable per serializzazione)
struct SalvadanaiModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: String // "objective", "glass", "infinite"
    var currentAmount: Double
    var targetAmount: Double
    var targetDate: Date?
    var monthlyRefill: Double
    var color: String
    var accountName: String
    var createdAt: Date
    var isInfinite: Bool
}

// MARK: - Transaction Model (MODIFICATO)
struct TransactionModel: Identifiable, Codable {
    let id = UUID()
    var amount: Double
    var descr: String
    var category: String
    var type: String // "expense", "income", "salary"
    var date: Date
    var accountName: String // Può essere vuoto per le spese
    var salvadanaiName: String?
}

struct AccountModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var balance: Double
    var createdAt: Date
}

// MARK: - Computed Properties aggiornate per DataManager
extension DataManager {
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalSavings: Double {
        salvadanai.reduce(0) { $0 + $1.currentAmount }
    }
    
    // NUOVO: Patrimonio totale considerando solo salvadanai positivi per il calcolo disponibile
    var availableBalance: Double {
        let positiveSavings = salvadanai.filter { $0.currentAmount > 0 }.reduce(0) { $0 + $1.currentAmount }
        return totalBalance + positiveSavings
    }
    
    var recentTransactions: [TransactionModel] {
        transactions.sorted { $0.date > $1.date }
    }
}

// MARK: - Data Manager con persistenza
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
    
    // Categorie complete (predefinite + personalizzate)
    var expenseCategories: [String] {
        return defaultExpenseCategories + customExpenseCategories.sorted()
    }
    
    var incomeCategories: [String] {
        return defaultIncomeCategories + customIncomeCategories.sorted()
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
    
    init() {
        loadAllData()
    }
    
    // MARK: - Persistence Methods
    private func loadAllData() {
        loadSalvadanai()
        loadTransactions()
        loadAccounts()
        loadStoredCategories()
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
    
    // MARK: - Categories Management
    func addExpenseCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !expenseCategories.contains(trimmedCategory) else { return }
        
        customExpenseCategories.append(trimmedCategory)
        // saveCategories() chiamato automaticamente da didSet
    }
    
    func addIncomeCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !incomeCategories.contains(trimmedCategory) else { return }
        
        customIncomeCategories.append(trimmedCategory)
        // saveCategories() chiamato automaticamente da didSet
    }
    
    func deleteExpenseCategory(_ category: String) {
        guard !defaultExpenseCategories.contains(category) else { return }
        customExpenseCategories.removeAll { $0 == category }
        // saveCategories() chiamato automaticamente da didSet
    }
    
    func deleteIncomeCategory(_ category: String) {
        guard !defaultIncomeCategories.contains(category) else { return }
        customIncomeCategories.removeAll { $0 == category }
        // saveCategories() chiamato automaticamente da didSet
    }
    
    // MARK: - Salvadanai Methods
    func addSalvadanaio(name: String, type: String, targetAmount: Double = 0, targetDate: Date? = nil, monthlyRefill: Double = 0, color: String, accountName: String, initialAmount: Double = 0, isInfinite: Bool = false) {
        let newSalvadanaio = SalvadanaiModel(
            name: name,
            type: type,
            currentAmount: initialAmount,
            targetAmount: isInfinite ? 0 : targetAmount,
            targetDate: isInfinite ? nil : targetDate,
            monthlyRefill: monthlyRefill,
            color: color,
            accountName: accountName,
            createdAt: Date(),
            isInfinite: isInfinite
        )
        salvadanai.append(newSalvadanaio)
        
        // Se c'è un saldo iniziale, sottrailo dal conto selezionato
        if initialAmount > 0 {
            updateAccountBalance(accountName: accountName, amount: -initialAmount)
        }
    }
    
    func updateSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        if let index = salvadanai.firstIndex(where: { $0.id == salvadanaio.id }) {
            salvadanai[index] = salvadanaio
        }
    }
    
    func deleteSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        salvadanai.removeAll { $0.id == salvadanaio.id }
    }
    
    // MARK: - Transaction Methods (MODIFICATO)
    func addTransaction(amount: Double, descr: String, category: String, type: String, accountName: String? = nil, salvadanaiName: String? = nil) {
        let newTransaction = TransactionModel(
            amount: amount,
            descr: descr,
            category: category,
            type: type,
            date: Date(),
            accountName: accountName ?? "", // Per spese sarà vuoto, per entrate avrà il conto
            salvadanaiName: salvadanaiName
        )
        transactions.append(newTransaction)
        
        if type == "expense" {
            // Per le spese: sottrai SOLO dal salvadanaio
            if let salvadanaiName = salvadanaiName {
                updateSalvadanaiBalance(name: salvadanaiName, amount: -amount)
            }
        } else {
            // Per entrate e stipendi: aggiungi al conto selezionato
            if let accountName = accountName {
                updateAccountBalance(accountName: accountName, amount: amount)
            }
        }
    }

    // MARK: - Metodo per eliminare transazioni (MODIFICATO)
    func deleteTransaction(_ transaction: TransactionModel) {
        transactions.removeAll { $0.id == transaction.id }
        
        if transaction.type == "expense" {
            // Per le spese: ripristina il saldo del salvadanaio
            if let salvadanaiName = transaction.salvadanaiName {
                updateSalvadanaiBalance(name: salvadanaiName, amount: transaction.amount)
            }
        } else {
            // Per entrate: ripristina il saldo del conto
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
    
    // MARK: - Distribution Methods
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
                    updateAccountBalance(accountName: salvadanai[index].accountName, amount: -customAmount)
                }
            }
        }
    }
    
    func distributeIncome(amount: Double, toSalvadanai selectedSalvadanai: [String], accountName: String, transactionType: String = "salary") {
        let descriptionText = transactionType == "salary" ? "Stipendio" : "Entrata"
        let categoryText = transactionType == "salary" ? "💼 Stipendio" : "💸 Entrata"
        
        addTransaction(
            amount: amount,
            descr: descriptionText,
            category: categoryText,
            type: transactionType,
            accountName: accountName
        )
        
        for salvadanaiName in selectedSalvadanai {
            if let index = salvadanai.firstIndex(where: { $0.name == salvadanaiName }) {
                var amountToAdd: Double = 0
                
                if salvadanai[index].type == "glass" {
                    let targetAmount = salvadanai[index].monthlyRefill
                    let currentAmount = salvadanai[index].currentAmount
                    amountToAdd = max(0, targetAmount - currentAmount)
                } else {
                    let remainingToTarget = salvadanai[index].targetAmount - salvadanai[index].currentAmount
                    amountToAdd = min(100, max(0, remainingToTarget))
                }
                
                if amountToAdd > 0 {
                    salvadanai[index].currentAmount += amountToAdd
                    updateAccountBalance(accountName: salvadanai[index].accountName, amount: -amountToAdd)
                }
            }
        }
    }
}
