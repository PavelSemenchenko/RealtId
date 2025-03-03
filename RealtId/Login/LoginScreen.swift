import SwiftUI

struct LoginScreen: View {
    @StateObject private var viewModel = LoginVM()
    @State private var email = "1@1.com"
    @State private var password = "123456"
    @State private var isRegistering = false
    @State private var showResetPassword = false
    @State private var isLoggedIn = false
    @State private var showCodeInput = false // Для показа окна ввода кода
    @State private var enteredCode = "" // Введённый пользователем код
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                ContentView()
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0/255, green: 66/255, blue: 64/255),
                            Color(red: 6/255, green: 157/255, blue: 124/255),
                            Color(red: 0/255, green: 66/255, blue: 64/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text(isRegistering ? "Регистрация" : "Вход")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Пароль", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            if isRegistering {
                                showCodeInput = true // Показать окно ввода кода
                            } else {
                                viewModel.signIn(email: email, password: password)
                            }
                        }) {
                            Text(isRegistering ? "Регистрация" : "Войти")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0/255, green: 66/255, blue: 64/255))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            isRegistering.toggle()
                        }) {
                            Text(isRegistering ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Button(action: {
                            showResetPassword = true
                        }) {
                            Text(isRegistering ? "" : "Сбросить пароль")
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        .sheet(isPresented: $showResetPassword) {
                            ResetPasswordView(viewModel: viewModel, email: $email)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .navigationBarHidden(true)
                    .alert(isPresented: $viewModel.showCodeAlert) {
                        Alert(
                            title: Text("Ошибка"),
                            message: Text("Код не верный, нет доступа"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    .sheet(isPresented: $showCodeInput) {
                        CodeInputView(viewModel: viewModel, code: $enteredCode, onSubmit: { code in
                            viewModel.checkRegistrationCode(code) { isValid in
                                if isValid {
                                    viewModel.signUp(email: email, password: password)
                                }
                                showCodeInput = false // Закрываем окно после проверки
                            }
                        })
                    }
                    .onChange(of: viewModel.isAuthenticated) { newValue in
                        if newValue {
                            isLoggedIn = true
                        }
                    }/* для ios 17+
                    .onChange(of: viewModel.isAuthenticated) { oldValue, newValue in
                        if newValue {
                            isLoggedIn = true
                        }
                    }*/
                }
            }
        }
    }
}

import SwiftUI

struct CodeInputView: View {
    @ObservedObject var viewModel: LoginVM
    @Binding var code: String
    let onSubmit: (String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack { // Используем ZStack для наложения фона на весь экран
                Color.red // Красный фон на весь экран
                    .edgesIgnoringSafeArea(.all) // Фон занимает всю область экрана, включая безопасные зоны
                
                VStack(spacing: 20) {
                    Text("Введите регистрационный код")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Код", text: $code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .background(Color.white.opacity(0.8))
                    
                    Button(action: {
                        onSubmit(code)
                    }) {
                        Text("Подтвердить")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// Экран сброса пароля (без изменений)
struct ResetPasswordView: View {
    @ObservedObject var viewModel: LoginVM
    @Binding var email: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Сброс пароля")
                .font(.headline)
            
            TextField("Введите ваш email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            Button("Отправить ссылку для сброса") {
                viewModel.resetPassword(email: email)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    LoginScreen()
}
