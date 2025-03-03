//
//  LoginVM.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 03.03.2025.
//
import FirebaseAuth
import SwiftUI

class LoginVM: ObservableObject {
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    init() {
        isAuthenticated = Auth.auth().currentUser != nil
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.isAuthenticated = true
                    self.errorMessage = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.isAuthenticated = true
                    self.errorMessage = nil
                }
            }
        }
    }
    
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = "Ссылка для сброса пароля отправлена на \(email)"
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Ошибка при выходе: \(error.localizedDescription)"
        }
    }
}
