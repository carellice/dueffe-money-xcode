import SwiftUI

// MARK: - Enhanced Settings View
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCategoriesManagement = false
    @State private var showingAboutApp = false
    @State private var showingExportData = false
    
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
                        SectionHeader(icon: "wand.and.stars.fill", title: "Personalizzazione")
                    } footer: {
                        Text("Modifica l'aspetto e il comportamento dell'app secondo le tue preferenze")
                    }
                    
                    // Dati e Backup
                    Section {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .blue,
                            title: "Esporta Dati",
                            subtitle: "Backup dei tuoi dati finanziari",
                            action: { showingExportData = true }
                        )
                        
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "Cancella Tutti i Dati",
                            subtitle: "Rimuovi completamente tutti i dati",
                            action: { /* Implementation needed */ },
                            isDestructive: true
                        )
                    } header: {
                        SectionHeader(icon: "server.rack.fill", title: "Dati e Backup")
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

// MARK: - App Info Card
struct AppInfoCard: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                
                Image(systemName: "app.badge.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Dueffe")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("La tua app per il risparmio intelligente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text("Versione 1.0")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                    
                    Text("Aggiornata")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                        .foregroundColor(.green)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            animateIcon = true
        }
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

// MARK: - Stat Card
struct StatCard: View {
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

// MARK: - Enhanced Categories Management View
struct EnhancedCategoriesManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingQuickAddExpense = false
    @State private var showingQuickAddIncome = false
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
                    // Header con statistiche
                    CategoriesStatsHeader(
                        expenseCount: dataManager.defaultExpenseCategories.count + dataManager.customExpenseCategories.count,
                        incomeCount: dataManager.defaultIncomeCategories.count + dataManager.customIncomeCategories.count,
                        customCount: dataManager.customExpenseCategories.count + dataManager.customIncomeCategories.count
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Tab Selector migliorato
                    Picker("Tipo", selection: $selectedTab) {
                        Text("Spese (\(dataManager.expenseCategories.count))").tag(0)
                        Text("Entrate (\(dataManager.incomeCategories.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Categories List
                    List {
                        if selectedTab == 0 {
                            // Expense Categories
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
                            
                        } else {
                            // Income Categories
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
                        }
                        
                        // Add Category Section
                        Section {
                            AddCategoryRow(
                                title: selectedTab == 0 ? "Aggiungi categoria spesa" : "Aggiungi categoria entrata",
                                color: selectedTab == 0 ? .red : .green,
                                action: {
                                    if selectedTab == 0 {
                                        showingQuickAddExpense = true
                                    } else {
                                        showingQuickAddIncome = true
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
                        color: selectedTab == 0 ? .red : .green,
                        action: {
                            if selectedTab == 0 {
                                showingQuickAddExpense = true
                            } else {
                                showingQuickAddIncome = true
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
        .alert("Elimina Categoria", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                if selectedTab == 0 {
                    dataManager.deleteExpenseCategory(categoryToDelete)
                } else {
                    dataManager.deleteIncomeCategory(categoryToDelete)
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

// MARK: - Categories Stats Header
struct CategoriesStatsHeader: View {
    let expenseCount: Int
    let incomeCount: Int
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

// MARK: - Enhanced Quick Category Add View
struct EnhancedQuickCategoryAddView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let categoryType: String
    @State private var categoryName = ""
    @State private var selectedEmoji = "📝"
    @State private var useEmoji = true
    
    let commonEmojis = ["📝", "💰", "🏠", "🚗", "🍕", "🎬", "👕", "🏥", "📚", "🎁", "💼", "📈", "💸", "🔄", "⚡", "🎮", "☕", "🛒", "💊", "🎯", "🎨", "🔧", "🎪", "⛽"]
    
    var title: String {
        categoryType == "expense" ? "Nuova Categoria Spesa" : "Nuova Categoria Entrata"
    }
    
    var color: Color {
        categoryType == "expense" ? .red : .green
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
                            color: color,
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
                        Text("Esempio: \(categoryType == "expense" ? "Benzina, Gaming, Farmaci" : "Cashback, Rimborsi, Vendite")")
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
    }
    
    private func addCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (useEmoji && !selectedEmoji.isEmpty) ? "\(selectedEmoji) \(trimmedName)" : trimmedName
        
        if categoryType == "expense" {
            dataManager.addExpenseCategory(finalName)
        } else {
            dataManager.addIncomeCategory(finalName)
        }
        
        dismiss()
    }
}

// MARK: - Category Preview Card
struct CategoryPreviewCard: View {
    let categoryName: String
    let emoji: String
    let color: Color
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
                                .fill(color.opacity(0.1))
                        )
                } else {
                    Image(systemName: "tag.fill")
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
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
                        .stroke(color.opacity(0.3), lineWidth: 1)
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
                            
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
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

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Esporta i tuoi dati")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Funzionalità in arrivo nella prossima versione")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                Button("Ho capito") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Esporta Dati")
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
