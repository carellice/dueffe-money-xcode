import SwiftUI

struct BiometricAuthView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var showingError = false
    @State private var animateIcon = false
    @State private var attemptedAuth = false
    
    let onAuthenticationSuccess: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // Logo e titolo
                VStack(spacing: 30) {
                    // Logo dell'app (se disponibile)
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .white.opacity(0.3), radius: 10)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                    
                    VStack(spacing: 16) {
                        Text("Dueffe Money")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Accesso sicuro ai tuoi dati finanziari")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Sezione di autenticazione
                VStack(spacing: 40) {
                    // Icona biometrica
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                            
                            Image(systemName: authManager.biometricIcon)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Text("Usa \(authManager.biometricTypeName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    // Pulsante di autenticazione
                    VStack(spacing: 20) {
                        Button(action: {
                            authenticate()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: authManager.biometricIcon)
                                    .font(.title2)
                                
                                Text("Sblocca con \(authManager.biometricTypeName)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            )
                        }
                        .disabled(attemptedAuth)
                        
                        // Pulsante alternativo per codice
                        Button(action: {
                            authenticateWithPasscode()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "key.fill")
                                    .font(.title3)
                                
                                Text("Usa Codice Dispositivo")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(attemptedAuth)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("I tuoi dati sono protetti e rimangono sul dispositivo")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            animateIcon = true
            // Prova l'autenticazione automatica al primo caricamento
            if !attemptedAuth {
                authenticate()
            }
        }
        .alert("Errore di Autenticazione", isPresented: $showingError) {
            Button("Riprova") {
                authenticate()
            }
            Button("Usa Codice") {
                authenticateWithPasscode()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text(authManager.authenticationError ?? "Si è verificato un errore durante l'autenticazione")
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onAuthenticationSuccess()
            }
        }
    }
    
    private func authenticate() {
        attemptedAuth = true
        
        Task {
            let success = await authManager.requestBiometricUnlock()
            
            await MainActor.run {
                if !success && authManager.authenticationError != nil {
                    showingError = true
                }
                attemptedAuth = false
            }
        }
    }
    
    private func authenticateWithPasscode() {
        attemptedAuth = true
        
        Task {
            let success = await authManager.requestAuthentication()
            
            await MainActor.run {
                if !success && authManager.authenticationError != nil {
                    showingError = true
                }
                attemptedAuth = false
            }
        }
    }
}

#Preview {
    BiometricAuthView {
        print("Autenticazione riuscita!")
    }
} 