//
//  LoginVM.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 03.03.2025.
//
import FirebaseAuth
import SwiftUI
import FirebaseFirestore

class LoginVM: ObservableObject {
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var showCodeAlert = false // Для отображения всплывающего окна с ошибкой кода
    private var db = Firestore.firestore()
    
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
    
    // Проверка кода из Firestore
    func checkRegistrationCode(_ enteredCode: String, completion: @escaping (Bool) -> Void) {
        let registerCodeRef = db.collection("RegisterCode")
        
        registerCodeRef.getDocuments { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Ошибка при проверке кода: \(error.localizedDescription)"
                    completion(false)
                }
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "Код не найден в базе данных"
                    completion(false)
                }
                return
            }
            
            // Проверяем поле code1 в любом документе коллекции
            for document in documents {
                if let code = document.data()["code1"] as? String, code == enteredCode {
                    DispatchQueue.main.async {
                        self.errorMessage = nil
                        completion(true)
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.errorMessage = "Код не верный, нет доступа"
                self.showCodeAlert = true
                completion(false)
            }
        }
    }
}
