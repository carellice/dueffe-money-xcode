import SwiftUI

// MARK: - Enhanced Settings View con Cancella Dati
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCategoriesManagement = false
    @State private var showingAboutApp = false
    @State private var showingExportData = false
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.05), Color.secondary.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Personalizzazione
                    Section {
                        SettingsRow(
                            icon: "tag.fill",
                            iconColor: .purple,
                            title: "Gestisci Categorie",
                            subtitle: "Personalizza categorie di spese e entrate",
                            action: { showingCategoriesManagement = true }
                        )
                        
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: .orange,
                            title: "Personalizzazione",
                            subtitle: "Temi e aspetto dell'app",
                            action: { /* Future implementation */ },
                            isComingSoon: true
                        )
                    } header: {
                        SectionHeader(icon: "paintbrush.pointed.fill", title: "Personalizzazione")
                    } footer: {
                        Text("Modifica l'aspetto e il comportamento dell'app secondo le tue preferenze")
                    }
                    
                    // Dati e Backup
                    Section {
                        SettingsRow(
                            icon: "document.fill",
                            iconColor: .blue,
                            title: "Esporta/Importa Dati",
                            subtitle: "Backup dei tuoi dati finanziari",
                            action: { showingExportData = true }
                        )
                        
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "Cancella Tutti i Dati",
                            subtitle: "Rimuovi completamente tutti i dati",
                            action: { showingDeleteAllAlert = true },
                            isDestructive: true
                        )
                    } header: {
                        SectionHeader(icon: "externaldrive.fill", title: "Dati e Backup")
                    } footer: {
                        Text("Gestisci i tuoi dati e crea backup di sicurezza")
                    }
                    
                    // Statistiche dell'app
                    Section {
                        AppStatisticsCard(dataManager: dataManager)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Supporto e Info
                    Section {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .green,
                            title: "Aiuto e Supporto",
                            subtitle: "Guide e assistenza",
                            action: { /* Future implementation */ },
                            isComingSoon: true
                        )
                        
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .blue,
                            title: "Informazioni App",
                            subtitle: "Versione, crediti e licenze",
                            action: { showingAboutApp = true }
                        )
                    } header: {
                        SectionHeader(icon: "questionmark.circle.fill", title: "Supporto")
                    }
                    
                    // Footer con versione
                    Section {
                        VStack(spacing: 12) {
                            Text("Dueffe v1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Sviluppato con ❤️ per aiutarti a risparmiare")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Impostazioni")
        }
        .sheet(isPresented: $showingCategoriesManagement) {
            EnhancedCategoriesManagementView()
        }
        .sheet(isPresented: $showingAboutApp) {
            AboutAppView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
        .alert("Cancella Tutti i Dati", isPresented: $showingDeleteAllAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Continua", role: .destructive) {
                showingDeleteConfirmation = true
            }
        } message: {
            Text("⚠️ ATTENZIONE: Questa azione cancellerà TUTTI i tuoi dati in modo permanente.\n\n• Tutti i salvadanai\n• Tutte le transazioni\n• Tutti i conti\n• Tutte le categorie personalizzate\n\nQuesta azione non può essere annullata!")
        }
        .alert("Conferma Cancellazione", isPresented: $showingDeleteConfirmation) {
            TextField("Scrivi CANCELLA per confermare", text: $deleteConfirmationText)
            Button("Annulla", role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("CANCELLA TUTTO", role: .destructive) {
                if deleteConfirmationText.uppercased() == "CANCELLA" {
                    deleteAllData()
                }
                deleteConfirmationText = ""
            }
            .disabled(deleteConfirmationText.uppercased() != "CANCELLA")
        } message: {
            Text("Per confermare la cancellazione di TUTTI i dati, scrivi 'CANCELLA' nel campo sopra.")
        }
    }
    
    private func deleteAllData() {
        withAnimation {
            // Cancella tutti i dati dal DataManager
            dataManager.salvadanai.removeAll()
            dataManager.transactions.removeAll()
            dataManager.accounts.removeAll()
            dataManager.customExpenseCategories.removeAll()
            dataManager.customIncomeCategories.removeAll()
            dataManager.customSalvadanaiCategories.removeAll()
        }
        
        // NUOVO: Reset dei flag di onboarding
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasCreatedFirstSalvadanaio")
        UserDefaults.standard.removeObject(forKey: "hasAddedInitialBalance")
        
        // Mostra feedback di successo
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Settings Stat Card
struct SettingsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
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
}

// MARK: - Section Header
struct SectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    let isComingSoon: Bool
    let isDestructive: Bool
    
    init(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void, isComingSoon: Bool = false, isDestructive: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isComingSoon = isComingSoon
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: isComingSoon ? {} : action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(isDestructive ? .red : .primary)
                        
                        if isComingSoon {
                            Text("Presto")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if !isComingSoon {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isComingSoon)
        .opacity(isComingSoon ? 0.6 : 1.0)
    }
}

// MARK: - App Statistics Card
struct AppStatisticsCard: View {
    let dataManager: DataManager
    
    private var totalTransactionAmount: Double {
        dataManager.transactions.reduce(0) { $0 + $1.amount }
    }
    
    private var daysSinceFirstTransaction: Int {
        guard let firstTransaction = dataManager.transactions.min(by: { $0.date < $1.date }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstTransaction.date, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Statistiche dell'App")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SettingsStatCard(
                    title: "Salvadanai",
                    value: "\(dataManager.salvadanai.count)",
                    icon: "banknote.fill",
                    color: Color.green
                )
                
                SettingsStatCard(
                    title: "Transazioni",
                    value: "\(dataManager.transactions.count)",
                    icon: "creditcard.fill",
                    color: Color.orange
                )
                
                SettingsStatCard(
                    title: "Conti",
                    value: "\(dataManager.accounts.count)",
                    icon: "building.columns.fill",
                    color: Color.blue
                )
                
                SettingsStatCard(
                    title: "Categorie",
                    value: "\(dataManager.customExpenseCategories.count + dataManager.customIncomeCategories.count)",
                    icon: "tag.fill",
                    color: Color.purple
                )
            }
            
            if daysSinceFirstTransaction > 0 {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Utilizzo dell'App")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("\(daysSinceFirstTransaction) giorni di utilizzo")
                            .font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "eurosign.circle")
                            .foregroundColor(.green)
                        Text("€\(String(format: "%.0f", totalTransactionAmount)) gestiti")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Enhanced Categories Management View AGGIORNATA
struct EnhancedCategoriesManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0 // 0=Spese, 1=Entrate, 2=Salvadanai
    @State private var showingQuickAddExpense = false
    @State private var showingQuickAddIncome = false
    @State private var showingQuickAddSalvadanaio = false // NUOVO
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete = ""
    @State private var searchText = ""
    
    var filteredExpenseCategories: [String] {
        if searchText.isEmpty {
            return dataManager.customExpenseCategories.sorted()
        } else {
            return dataManager.customExpenseCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
        }
    }
    
    var filteredIncomeCategories: [String] {
        if searchText.isEmpty {
            return dataManager.customIncomeCategories.sorted()
        } else {
            return dataManager.customIncomeCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
        }
    }
    
    // NUOVO: Filtro per categorie salvadanai
    var filteredSalvadanaiCategories: [String] {
        if searchText.isEmpty {
            return dataManager.customSalvadanaiCategories.sorted()
        } else {
            return dataManager.customSalvadanaiCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con statistiche AGGIORNATO
                    CategoriesStatsHeader(
                        expenseCount: dataManager.defaultExpenseCategories.count + dataManager.customExpenseCategories.count,
                        incomeCount: dataManager.defaultIncomeCategories.count + dataManager.customIncomeCategories.count,
                        salvadanaiCount: dataManager.defaultSalvadanaiCategories.count + dataManager.customSalvadanaiCategories.count, // NUOVO
                        customCount: dataManager.customExpenseCategories.count + dataManager.customIncomeCategories.count + dataManager.customSalvadanaiCategories.count // AGGIORNATO
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Tab Selector migliorato AGGIORNATO
                    Picker("Tipo", selection: $selectedTab) {
                        Text("Spese (\(dataManager.expenseCategories.count))").tag(0)
                        Text("Entrate (\(dataManager.incomeCategories.count))").tag(1)
                        Text("Salvadanai (\(dataManager.allSalvadanaiCategories.count))").tag(2) // NUOVO
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Categories List
                    List {
                        if selectedTab == 0 {
                            // Expense Categories (INVARIATO)
                            Section {
                                ForEach(dataManager.defaultExpenseCategories, id: \.self) { category in
                                    CategoryRow(
                                        category: category,
                                        isDefault: true,
                                        color: .red,
                                        onDelete: nil
                                    )
                                }
                            } header: {
                                CategorySectionHeader(
                                    title: "Categorie Predefinite",
                                    count: dataManager.defaultExpenseCategories.count,
                                    color: .blue
                                )
                            }
                            
                            if !filteredExpenseCategories.isEmpty {
                                Section {
                                    ForEach(filteredExpenseCategories, id: \.self) { category in
                                        CategoryRow(
                                            category: category,
                                            isDefault: false,
                                            color: .red,
                                            onDelete: {
                                                categoryToDelete = category
                                                showingDeleteAlert = true
                                            }
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Elimina", role: .destructive) {
                                                dataManager.deleteExpenseCategory(category)
                                            }
                                        }
                                    }
                                } header: {
                                    CategorySectionHeader(
                                        title: "Categorie Personalizzate",
                                        count: filteredExpenseCategories.count,
                                        color: .purple
                                    )
                                } footer: {
                                    Text("Scorri verso sinistra per eliminare una categoria personalizzata")
                                }
                            }
                            
                        } else if selectedTab == 1 {
                            // Income Categories (INVARIATO)
                            Section {
                                ForEach(dataManager.defaultIncomeCategories, id: \.self) { category in
                                    CategoryRow(
                                        category: category,
                                        isDefault: true,
                                        color: .green,
                                        onDelete: nil
                                    )
                                }
                            } header: {
                                CategorySectionHeader(
                                    title: "Categorie Predefinite",
                                    count: dataManager.defaultIncomeCategories.count,
                                    color: .blue
                                )
                            }
                            
                            if !filteredIncomeCategories.isEmpty {
                                Section {
                                    ForEach(filteredIncomeCategories, id: \.self) { category in
                                        CategoryRow(
                                            category: category,
                                            isDefault: false,
                                            color: .green,
                                            onDelete: {
                                                categoryToDelete = category
                                                showingDeleteAlert = true
                                            }
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Elimina", role: .destructive) {
                                                dataManager.deleteIncomeCategory(category)
                                            }
                                        }
                                    }
                                } header: {
                                    CategorySectionHeader(
                                        title: "Categorie Personalizzate",
                                        count: filteredIncomeCategories.count,
                                        color: .purple
                                    )
                                } footer: {
                                    Text("Scorri verso sinistra per eliminare una categoria personalizzata")
                                }
                            }
                            
                        } else {
                            // NUOVO: Salvadanai Categories
                            Section {
                                ForEach(dataManager.defaultSalvadanaiCategories, id: \.self) { category in
                                    CategoryRow(
                                        category: category,
                                        isDefault: true,
                                        color: .orange,
                                        onDelete: nil
                                    )
                                }
                            } header: {
                                CategorySectionHeader(
                                    title: "Categorie Predefinite",
                                    count: dataManager.defaultSalvadanaiCategories.count,
                                    color: .blue
                                )
                            }
                            
                            if !filteredSalvadanaiCategories.isEmpty {
                                Section {
                                    ForEach(filteredSalvadanaiCategories, id: \.self) { category in
                                        CategoryRow(
                                            category: category,
                                            isDefault: false,
                                            color: .orange,
                                            onDelete: {
                                                categoryToDelete = category
                                                showingDeleteAlert = true
                                            }
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Elimina", role: .destructive) {
                                                dataManager.deleteSalvadanaiCategory(category)
                                            }
                                        }
                                    }
                                } header: {
                                    CategorySectionHeader(
                                        title: "Categorie Personalizzate",
                                        count: filteredSalvadanaiCategories.count,
                                        color: .purple
                                    )
                                } footer: {
                                    Text("Scorri verso sinistra per eliminare una categoria personalizzata")
                                }
                            }
                        }
                        
                        // Add Category Section AGGIORNATO
                        Section {
                            AddCategoryRow(
                                title: selectedTab == 0 ? "Aggiungi categoria spesa" :
                                       selectedTab == 1 ? "Aggiungi categoria entrata" :
                                       "Aggiungi categoria salvadanaio", // NUOVO
                                color: selectedTab == 0 ? .red : selectedTab == 1 ? .green : .orange, // AGGIORNATO
                                action: {
                                    if selectedTab == 0 {
                                        showingQuickAddExpense = true
                                    } else if selectedTab == 1 {
                                        showingQuickAddIncome = true
                                    } else {
                                        showingQuickAddSalvadanaio = true // NUOVO
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .searchable(text: $searchText, prompt: "Cerca categorie...")
                    .background(Color.clear)
                }
            }
            .navigationTitle("Gestione Categorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    FloatingActionButton(
                        icon: "plus.circle.fill",
                        color: selectedTab == 0 ? .red : selectedTab == 1 ? .green : .orange, // AGGIORNATO
                        action: {
                            if selectedTab == 0 {
                                showingQuickAddExpense = true
                            } else if selectedTab == 1 {
                                showingQuickAddIncome = true
                            } else {
                                showingQuickAddSalvadanaio = true // NUOVO
                            }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingQuickAddExpense) {
            EnhancedQuickCategoryAddView(categoryType: "expense")
        }
        .sheet(isPresented: $showingQuickAddIncome) {
            EnhancedQuickCategoryAddView(categoryType: "income")
        }
        .sheet(isPresented: $showingQuickAddSalvadanaio) { // NUOVO
            EnhancedQuickCategoryAddView(categoryType: "salvadanaio")
        }
        .alert("Elimina Categoria", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                if selectedTab == 0 {
                    dataManager.deleteExpenseCategory(categoryToDelete)
                } else if selectedTab == 1 {
                    dataManager.deleteIncomeCategory(categoryToDelete)
                } else {
                    dataManager.deleteSalvadanaiCategory(categoryToDelete) // NUOVO
                }
                categoryToDelete = ""
            }
            Button("Annulla", role: .cancel) {
                categoryToDelete = ""
            }
        } message: {
            Text("Sei sicuro di voler eliminare la categoria '\(categoryToDelete)'? Questa azione non può essere annullata.")
        }
    }
}

// MARK: - Categories Stats Header AGGIORNATO
struct CategoriesStatsHeader: View {
    let expenseCount: Int
    let incomeCount: Int
    let salvadanaiCount: Int // NUOVO
    let customCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.purple)
                Text("Categorie Totali")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 20) {
                CategoryStatItem(
                    title: "Spese",
                    count: expenseCount,
                    icon: "minus.circle.fill",
                    color: .red
                )
                
                CategoryStatItem(
                    title: "Entrate",
                    count: incomeCount,
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                // NUOVO: Statistiche salvadanai
                CategoryStatItem(
                    title: "Salvadanai",
                    count: salvadanaiCount,
                    icon: "banknote.fill",
                    color: .orange
                )
                
                CategoryStatItem(
                    title: "Personalizzate",
                    count: customCount,
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Category Stat Item
struct CategoryStatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
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

// MARK: - Category Section Header
struct CategorySectionHeader: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(color)
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: String
    let isDefault: Bool
    let color: Color
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji or icon
            if let firstChar = category.first, firstChar.isEmoji {
                Text(String(firstChar))
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
            } else {
                Image(systemName: "tag.fill")
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(isDefault ? "Predefinita" : "Personalizzata")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((isDefault ? Color.blue : Color.purple).opacity(0.1))
                        )
                        .foregroundColor(isDefault ? .blue : .purple)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            if !isDefault, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Category Row
struct AddCategoryRow: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Quick Category Add View AGGIORNATO
struct EnhancedQuickCategoryAddView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let categoryType: String
    @State private var categoryName = ""
    @State private var selectedEmoji = "📝"
    @State private var useEmoji = true
    
    // AGGIORNATO: Emoji per salvadanai
    let commonEmojis = ["📝", "💰", "🏠", "🚗", "🍕", "🎬", "👕", "🏥", "📚", "🎁", "💼", "📈", "💸", "🔄", "⚡", "🎮", "☕", "🛒", "💊", "🎯", "🎨", "🔧", "🎪", "⛽", "📁", "✈️", "🎓", "🏋️", "🎵", "💒", "🐕", "🌱"]
    
    var title: String {
        switch categoryType {
        case "expense": return "Nuova Categoria Spesa"
        case "income": return "Nuova Categoria Entrata"
        case "salvadanaio": return "Nuova Categoria Salvadanaio" // NUOVO
        default: return "Nuova Categoria"
        }
    }
    
    var color: Color {
        switch categoryType {
        case "expense": return .red
        case "income": return .green
        case "salvadanaio": return .orange // NUOVO
        default: return .blue
        }
    }
    
    var exampleText: String {
        switch categoryType {
        case "expense": return "Esempio: Benzina, Gaming, Farmaci"
        case "income": return "Esempio: Cashback, Rimborsi, Vendite"
        case "salvadanaio": return "Esempio: Sport e Palestra, Matrimonio, Fondo Emergenza" // NUOVO
        default: return "Esempio: Nuova Categoria"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.05), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Anteprima
                    Section {
                        CategoryPreviewCard(
                            categoryName: categoryName.isEmpty ? "Nome categoria" : categoryName,
                            emoji: useEmoji ? selectedEmoji : "",
                            isEmpty: categoryName.isEmpty
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Nome categoria
                    Section {
                        TextField("Nome categoria", text: $categoryName)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                    } header: {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(color)
                            Text("Nome")
                        }
                    } footer: {
                        Text(exampleText)
                    }
                    
                    // Emoji toggle
                    Section {
                        Toggle("Usa emoji", isOn: $useEmoji)
                            .toggleStyle(SwitchToggleStyle(tint: color))
                        
                        if useEmoji {
                            // Emoji selector migliorato
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Emoji selezionata: \(selectedEmoji)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(commonEmojis, id: \.self) { emoji in
                                        Button(action: {
                                            selectedEmoji = emoji
                                        }) {
                                            Text(emoji)
                                                .font(.title2)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(selectedEmoji == emoji ? color.opacity(0.2) : Color.gray.opacity(0.1))
                                                        .overlay(
                                                            Circle()
                                                                .stroke(selectedEmoji == emoji ? color : Color.clear, lineWidth: 2)
                                                        )
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.orange)
                            Text("Icona (opzionale)")
                        }
                    } footer: {
                        Text(useEmoji ? "Seleziona un'emoji per rendere la categoria più riconoscibile" : "La categoria userà solo testo senza emoji")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aggiungi") {
                        addCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryName.isEmpty ? .secondary : color)
                }
            }
        }
        .onAppear {
            // NUOVO: Emoji di default per salvadanai
            if categoryType == "salvadanaio" {
                selectedEmoji = "📁"
            }
        }
    }
    
    private func addCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (useEmoji && !selectedEmoji.isEmpty) ? "\(selectedEmoji) \(trimmedName)" : trimmedName
        
        // AGGIORNATO: Switch per tipo categoria
        switch categoryType {
        case "expense":
            dataManager.addExpenseCategory(finalName)
        case "income":
            dataManager.addIncomeCategory(finalName)
        case "salvadanaio":
            dataManager.addSalvadanaiCategory(finalName) // NUOVO
        default:
            break
        }
        
        dismiss()
    }
}

// MARK: - NUOVO: Category Preview Card per Salvadanai
struct CategoryPreviewCard: View {
    let categoryName: String
    let emoji: String
    let isEmpty: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                Text("Anteprima")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.1))
                        )
                } else {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                        )
                }
                
                Text(categoryName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isEmpty ? .secondary : .primary)
                
                Spacer()
                
                Text("Personalizzata")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.1))
                    )
                    .foregroundColor(.purple)
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - About App View
struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image("AppLogo") // Usa il nome dell'immagine negli assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Dueffe")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("v1.0")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Descrizione
                    VStack(alignment: .leading, spacing: 16) {
                        Text("La tua app per il risparmio intelligente")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        Text("Dueffe ti aiuta a gestire i tuoi salvadanai e a raggiungere i tuoi obiettivi finanziari con facilità e stile.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Caratteristiche")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            FeatureRow(icon: "banknote.fill", title: "Salvadanai Intelligenti", description: "Crea obiettivi e salvadanai Glass per risparmiare")
                            FeatureRow(icon: "creditcard.fill", title: "Gestione Transazioni", description: "Tieni traccia di tutte le tue spese e entrate")
                            FeatureRow(icon: "building.columns.fill", title: "Multi-Conto", description: "Gestisci diversi conti e carte in un'unica app")
                            FeatureRow(icon: "chart.bar.fill", title: "Statistiche Dettagliate", description: "Analizza le tue abitudini finanziarie")
                        }
                    }
                    
                    // Crediti
                    VStack(spacing: 16) {
                        Text("Sviluppato con ❤️")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("© 2025 Dueffe. Tutti i diritti riservati.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Informazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingShareSheet = false
    @State private var showingImportPicker = false
    @State private var showingImportAlert = false
    @State private var showingExportError = false
    @State private var importResult = ImportResult(success: false, message: "")
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var exportErrorMessage = ""
    
    var hasData: Bool {
        !dataManager.accounts.isEmpty || !dataManager.salvadanai.isEmpty || !dataManager.transactions.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                                
                                if isExporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text("Backup e Ripristino")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(isExporting ? "Creazione backup in corso..." : "Esporta i tuoi dati o ripristina da un backup")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Statistiche dati attuali
                        if hasData {
                            DataStatsCard(dataManager: dataManager)
                        }
                        
                        // Azioni principali
                        VStack(spacing: 20) {
                            // Esporta
                            if hasData {
                                ActionCard(
                                    title: isExporting ? "Creazione backup..." : "Esporta Dati",
                                    subtitle: "Crea un backup completo dei tuoi dati",
                                    icon: "square.and.arrow.up.fill",
                                    color: .blue,
                                    action: { exportData() },
                                    isDisabled: isExporting
                                )
                            } else {
                                ActionCard(
                                    title: "Nessun Dato da Esportare",
                                    subtitle: "Aggiungi conti e transazioni per creare un backup",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .orange,
                                    action: { },
                                    isDisabled: true
                                )
                            }
                            
                            // Importa
                            ActionCard(
                                title: "Importa Dati",
                                subtitle: "Ripristina da un backup precedente",
                                icon: "square.and.arrow.down.fill",
                                color: .green,
                                action: { showingImportPicker = true },
                                isDisabled: isExporting
                            )
                        }
                        
                        // Info importante
                        InfoCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Backup Dati")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert("Importazione", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importResult.message)
        }
        .alert("Errore Esportazione", isPresented: $showingExportError) {
            Button("OK") { }
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    private func exportData() {
        // Prevenire export multipli
        guard !isExporting else { return }
        
        isExporting = true
        exportFileURL = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Genera i dati di export
            guard let exportData = dataManager.exportData() else {
                DispatchQueue.main.async {
                    exportErrorMessage = "Impossibile creare i dati di backup. Riprova."
                    showingExportError = true
                    isExporting = false
                }
                return
            }
            
            // Crea il nome del file
            let fileName = dataManager.getExportFileName()
            
            // Ottieni il percorso dei documenti temporanei
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                // Scrivi il file
                try exportData.write(to: fileURL)
                
                // Verifica che il file esista e sia leggibile
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    throw NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "File non creato correttamente"])
                }
                
                DispatchQueue.main.async {
                    exportFileURL = fileURL
                    isExporting = false
                    
                    // Piccolo delay per assicurarsi che tutto sia pronto
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingShareSheet = true
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    exportErrorMessage = "Errore nel salvataggio del file: \(error.localizedDescription)"
                    showingExportError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Assicurati di avere accesso al file
            guard url.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(success: false, message: "Impossibile accedere al file selezionato")
                showingImportAlert = true
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                importResult = dataManager.importData(from: data)
                showingImportAlert = true
                
                if importResult.success {
                    // Chiudi la vista dopo un successo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                importResult = ImportResult(success: false, message: "Impossibile leggere il file selezionato: \(error.localizedDescription)")
                showingImportAlert = true
            }
            
        case .failure(let error):
            importResult = ImportResult(success: false, message: "Errore nella selezione del file: \(error.localizedDescription)")
            showingImportAlert = true
        }
    }
}

struct DataStatsCard: View {
    let dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Dati Attuali")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatItem(title: "Conti", value: "\(dataManager.accounts.count)", icon: "building.columns.fill", color: .blue)
                StatItem(title: "Salvadanai", value: "\(dataManager.salvadanai.count)", icon: "banknote.fill", color: .green)
                StatItem(title: "Transazioni", value: "\(dataManager.transactions.count)", icon: "creditcard.fill", color: .orange)
                StatItem(title: "Categorie", value: "\(dataManager.customExpenseCategories.count + dataManager.customIncomeCategories.count + dataManager.customSalvadanaiCategories.count)", icon: "tag.fill", color: .purple)
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

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    
    init(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isDisabled ? 0.3 : 1.0))
                        .frame(width: 50, height: 50)
                        .shadow(color: isDisabled ? .clear : color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isDisabled ? Color.clear : color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

struct InfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Informazioni Importanti")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "checkmark.circle", text: "I backup sono in formato JSON e compatibili solo con Dueffe")
                InfoRow(icon: "shield.fill", text: "I tuoi dati rimangono sempre sul tuo dispositivo")
                InfoRow(icon: "exclamationmark.triangle", text: "L'importazione sostituisce tutti i dati attuali")
                InfoRow(icon: "icloud", text: "Salva i backup su iCloud o condividili via AirDrop")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

