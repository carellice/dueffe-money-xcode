import Foundation
import CoreData
import SwiftUI

// MARK: - Data Models
struct SalvadanaiModel: Identifiable {
    let id = UUID()
    var name: String
    var type: String // "objective", "glass", "infinite"
    var currentAmount: Double
    var targetAmount: Double
    var targetDate: Date?
    var monthlyRefill: Double
    var color: String
    var accountName: String // Conto associato al salvadanaio
    var createdAt: Date
    var isInfinite: Bool // Nuovo: indica se è un obiettivo infinito
}

struct TransactionModel: Identifiable {
    let id = UUID()
    var amount: Double
    var descr: String  // Cambiato da description a descr
    var category: String
    var type: String // "expense", "income", "salary"
    var date: Date
    var accountName: String
    var salvadanaiName: String?
}

struct AccountModel: Identifiable {
    let id = UUID()
    var name: String
    var balance: Double
    var createdAt: Date
}

// MARK: - Data Manager (versione con categorie personalizzabili)
class DataManager: ObservableObject {
    @Published var salvadanai: [SalvadanaiModel] = []
    @Published var transactions: [TransactionModel] = []
    @Published var accounts: [AccountModel] = []
    @Published var customExpenseCategories: [String] = [] // Nuove categorie spese personalizzate
    @Published var customIncomeCategories: [String] = []  // Nuove categorie entrate personalizzate
    
    // Computed Properties
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalSavings: Double {
        salvadanai.reduce(0) { $0 + $1.currentAmount }
    }
    
    var availableBalance: Double {
        totalBalance - totalSavings
    }
    
    var recentTransactions: [TransactionModel] {
        transactions.sorted { $0.date > $1.date }
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
    
    init() {
        // App inizia vuota
        loadStoredCategories() // Carica categorie salvate
    }
    
    // MARK: - Categories Management
    func addExpenseCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !expenseCategories.contains(trimmedCategory) else { return }
        
        customExpenseCategories.append(trimmedCategory)
        saveCategories()
    }
    
    func addIncomeCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !incomeCategories.contains(trimmedCategory) else { return }
        
        customIncomeCategories.append(trimmedCategory)
        saveCategories()
    }
    
    func deleteExpenseCategory(_ category: String) {
        // Può eliminare solo categorie personalizzate, non quelle predefinite
        guard !defaultExpenseCategories.contains(category) else { return }
        customExpenseCategories.removeAll { $0 == category }
        saveCategories()
    }
    
    func deleteIncomeCategory(_ category: String) {
        // Può eliminare solo categorie personalizzate, non quelle predefinite
        guard !defaultIncomeCategories.contains(category) else { return }
        customIncomeCategories.removeAll { $0 == category }
        saveCategories()
    }
    
    // MARK: - Categories Persistence
    private func saveCategories() {
        UserDefaults.standard.set(customExpenseCategories, forKey: "CustomExpenseCategories")
        UserDefaults.standard.set(customIncomeCategories, forKey: "CustomIncomeCategories")
    }
    
    private func loadStoredCategories() {
        customExpenseCategories = UserDefaults.standard.stringArray(forKey: "CustomExpenseCategories") ?? []
        customIncomeCategories = UserDefaults.standard.stringArray(forKey: "CustomIncomeCategories") ?? []
    }
    
    // MARK: - Existing methods remain the same...
    
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
    }
    
    func updateSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        if let index = salvadanai.firstIndex(where: { $0.id == salvadanaio.id }) {
            salvadanai[index] = salvadanaio
        }
    }
    
    func deleteSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        salvadanai.removeAll { $0.id == salvadanaio.id }
    }
    
    // MARK: - Transaction Methods
    func addTransaction(amount: Double, descr: String, category: String, type: String, accountName: String, salvadanaiName: String? = nil) {
        let newTransaction = TransactionModel(
            amount: amount,
            descr: descr,
            category: category,
            type: type,
            date: Date(),
            accountName: accountName,
            salvadanaiName: salvadanaiName
        )
        transactions.append(newTransaction)
        
        // Aggiorna il saldo del conto
        updateAccountBalance(accountName: accountName, amount: type == "expense" ? -amount : amount)
        
        // Se è una spesa, sottrai dal salvadanaio
        if type == "expense", let salvadanaiName = salvadanaiName {
            updateSalvadanaiBalance(name: salvadanaiName, amount: -amount)
        }
    }
    
    func deleteTransaction(_ transaction: TransactionModel) {
        transactions.removeAll { $0.id == transaction.id }
        
        // Ripristina il saldo
        let reverseAmount = transaction.type == "expense" ? transaction.amount : -transaction.amount
        updateAccountBalance(accountName: transaction.accountName, amount: reverseAmount)
        
        if transaction.type == "expense", let salvadanaiName = transaction.salvadanaiName {
            updateSalvadanaiBalance(name: salvadanaiName, amount: transaction.amount)
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
            // Rimossa la protezione che impediva di andare sotto zero
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

// MARK: - Color Extension
extension Color {
    init(_ colorName: String) {
        switch colorName {
        case "blue": self = .blue
        case "green": self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "red": self = .red
        case "yellow": self = .yellow
        case "indigo": self = .indigo
        default: self = .blue
        }
    }
}

// MARK: - Animation Helper
struct MoneyFlowAnimation: View {
    @State private var isAnimating = false
    let fromAccount: String
    let toSalvadanaio: String
    let amount: Double
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Smistamento in corso...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Animazione soldi
                HStack(spacing: 20) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "banknote.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
                
                VStack(spacing: 8) {
                    Text("€\(String(format: "%.2f", amount))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("da \(fromAccount) → \(toSalvadanaio)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
}
