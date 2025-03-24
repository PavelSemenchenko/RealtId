//
//  SplashScreen.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 03.03.2025.
//

import SwiftUI
import FirebaseAuth

struct SplashScreen: View {
    @State private var isActive = false
    @State private var isLoggedIn = Auth.auth().currentUser != nil
    @State private var animationProgress: CGFloat = 0 // Для управления анимацией
    @State private var textOpacity: Double = 0 // Для прозрачности текста
    
    var body: some View {
        Group {
            if isActive {
                if isLoggedIn {
                    ContentView()
                } else {
                    LoginScreen()
                }
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0/255, green: 66/255, blue: 64/255), // #004240 (тёмно-зелёный внизу)
                            Color(red: 5/255, green: 138/255, blue: 111/255), // #058a6f (средний зелёный)
                            Color(red: 6/255, green: 157/255, blue: 124/255)  // #069d7c (светло-зелёный вверху)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(animationProgress * 360))
                            Text("057")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(textOpacity) // Прозрачность текста
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 220/255, green: 53/255, blue: 69/255))
                                .opacity(textOpacity) // Прозрачность точки
                            
                            Text("estate")
                                .font(.system(size: 35))
                                .foregroundColor(Color(red: 220/255, green: 53/255, blue: 69/255))
                                .opacity(textOpacity) // Прозрачность текста
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Центрируем элементы
                }
                .onAppear {
                    // Анимация пина (вращение)
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                        animationProgress = 1
                    }
                    
                    // Анимация появления текста через прозрачность (fade-in)
                    withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
                        textOpacity = 1
                    }
                    
                    // Задержка перед переходом
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}
#Preview {
    SplashScreen()
}

