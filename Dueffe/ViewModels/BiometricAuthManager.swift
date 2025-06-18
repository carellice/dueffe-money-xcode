import Foundation
import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var authenticationError: String?
    
    // UserDefaults per salvare le impostazioni
    @AppStorage("biometricAuthEnabled") var biometricAuthEnabled = false
    @AppStorage("requireAuthOnLaunch") var requireAuthOnLaunch = true
    
    private let context = LAContext()
    
    init() {
        getBiometricType()
    }
    
    // MARK: - Controllo disponibilità biometria
    func getBiometricType() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        
        biometricType = context.biometryType
    }
    
    // MARK: - Controllo se la biometria è disponibile
    var isBiometricAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    // MARK: - Nome del tipo di biometria
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Autenticazione Biometrica"
        }
    }
    
    // MARK: - Icona del tipo di biometria
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }
    
    // MARK: - Richiesta autenticazione
    func requestBiometricUnlock() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Controlla se la biometria è disponibile
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            await MainActor.run {
                authenticationError = error?.localizedDescription ?? "Autenticazione biometrica non disponibile"
            }
            return false
        }
        
        // Configura il contesto
        context.localizedCancelTitle = "Annulla"
        context.localizedFallbackTitle = "Usa Codice"
        
        let reason = "Sblocca Dueffe Money per accedere ai tuoi dati finanziari"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            await MainActor.run {
                if success {
                    isAuthenticated = true
                    authenticationError = nil
                } else {
                    authenticationError = "Autenticazione fallita"
                }
            }
            
            return success
        } catch let error {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Richiesta autenticazione con codice di backup
    func requestAuthentication() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Prima prova la biometria, poi il codice dispositivo come fallback
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            await MainActor.run {
                authenticationError = error?.localizedDescription ?? "Nessun metodo di autenticazione disponibile"
            }
            return false
        }
        
        context.localizedCancelTitle = "Annulla"
        context.localizedFallbackTitle = "Usa Codice"
        
        let reason = "Sblocca Dueffe Money per accedere ai tuoi dati finanziari"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            
            await MainActor.run {
                if success {
                    isAuthenticated = true
                    authenticationError = nil
                } else {
                    authenticationError = "Autenticazione fallita"
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Reset autenticazione
    func resetAuthentication() {
        isAuthenticated = false
        authenticationError = nil
    }
    
    // MARK: - Abilita/Disabilita autenticazione biometrica
    func toggleBiometricAuth() async -> Bool {
        if biometricAuthEnabled {
            // Se sta disabilitando, non serve autenticazione
            biometricAuthEnabled = false
            requireAuthOnLaunch = false
            return true
        } else {
            // Se sta abilitando, richiedi autenticazione prima
            let success = await requestBiometricUnlock()
            if success {
                biometricAuthEnabled = true
                requireAuthOnLaunch = true // Automaticamente abilitato
            }
            return success
        }
    }
} 
