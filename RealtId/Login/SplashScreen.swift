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
    
    var body: some View {
        Group {
            if isActive {
                if isLoggedIn {
                    ContentView()
                } else {
                    LoginScreen()
                }
            } else {
                VStack {
                    Text("RealtId")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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

