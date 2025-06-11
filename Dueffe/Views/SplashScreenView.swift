import SwiftUI

// MARK: - Splash Screen View - File Completo
struct AnimatedSplashScreen: View {
    @State private var animateGradient = false
    @State private var animateLogo = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateCoins = false
    @State private var animateGlow = false
    @State private var animateParticles = false
    @State private var particlePositions: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background animato con gradiente
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.9),
                        Color.indigo.opacity(0.8),
                        Color.purple.opacity(0.9),
                        Color.pink.opacity(0.7),
                        Color.orange.opacity(0.8)
                    ]),
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
                
                // Overlay decorativo dinamico
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear,
                        Color.black.opacity(0.2)
                    ]),
                    center: animateGlow ? .topTrailing : .bottomLeading,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)
                
                // Particelle fluttuanti
                ForEach(Array(particlePositions.enumerated()), id: \.offset) { index, position in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .position(position)
                        .scaleEffect(animateParticles ? Double.random(in: 0.5...1.5) : 1.0)
                        .animation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true), value: animateParticles)
                }
                
                // Contenuto principale
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo area con animazioni
                    ZStack {
                        // Cerchi concentrici di background
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: CGFloat(120 + index * 30), height: CGFloat(120 + index * 30))
                                .scaleEffect(animateLogo ? 1.0 : 0.5)
                                .opacity(animateLogo ? 1.0 : 0.0)
                                .animation(.spring(response: 1.2, dampingFraction: 0.6).delay(Double(index) * 0.2), value: animateLogo)
                        }
                        
                        // Logo principale
                        ZStack {
                            // Background glow del logo
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateGlow ? 1.3 : 0.8)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                            
                            // Icona principale
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "banknote.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.white)
                                    .scaleEffect(animateLogo ? 1.0 : 0.3)
                                    .rotationEffect(.degrees(animateLogo ? 0 : -180))
                                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: animateLogo)
                            }
                            
                            // Monete decorative che orbitano
                            ForEach(0..<6, id: \.self) { index in
                                Image(systemName: index % 2 == 0 ? "eurosign.circle.fill" : "dollarsign.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                    .offset(
                                        x: animateCoins ? cos(Double(index) * .pi / 3) * 70 : 0,
                                        y: animateCoins ? sin(Double(index) * .pi / 3) * 70 : 0
                                    )
                                    .scaleEffect(animateCoins ? 1.0 : 0.0)
                                    .animation(
                                        .spring(response: 1.5, dampingFraction: 0.6)
                                        .delay(Double(index) * 0.1 + 0.8),
                                        value: animateCoins
                                    )
                            }
                        }
                    }
                    
                    // Titolo app
                    VStack(spacing: 16) {
                        Text("Dueffe")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .scaleEffect(animateTitle ? 1.0 : 0.8)
                            .opacity(animateTitle ? 1.0 : 0.0)
                            .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(1.2), value: animateTitle
                    }
                    
                    Spacer()
                    
                    // Loading indicator
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 40, height: 40)
                            
                            Circle()
                                .trim(from: 0, to: animateSubtitle ? 0.8 : 0)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(animateSubtitle ? 360 : 0))
                                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: animateSubtitle)
                        }
                        
                        Text("Caricamento...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(animateSubtitle ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.5).delay(1.8), value: animateSubtitle)
                    }
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            startAnimations()
            generateParticles()
        }
    }
    
    private func startAnimations() {
        // Sequenza animazioni
        withAnimation(.easeInOut(duration: 0.8)) {
            animateGradient = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateLogo = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateGlow = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                animateCoins = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                animateTitle = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                animateSubtitle = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                animateParticles = true
            }
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particlePositions = (0..<15).map { _ in
            CGPoint(
                x: Double.random(in: 0...Double(screenWidth)),
                y: Double.random(in: 0...Double(screenHeight))
            )
        }
    }
}
