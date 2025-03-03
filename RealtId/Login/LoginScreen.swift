import SwiftUI

struct LoginScreen: View {
    @StateObject private var viewModel = LoginVM()
    @State private var email = "1@1.com"
    @State private var password = "123456"
    @State private var isRegistering = false
    @State private var showResetPassword = false
    @State private var isLoggedIn = false // Для перехода после входа
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                ContentView() // Переход на ContentView после входа
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0/255, green: 66/255, blue: 64/255),
                            Color(red: 6/255, green: 157/255, blue: 124/255),
                            //Color(red: 5/255, green: 138/255, blue: 111/255),
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
                                viewModel.signUp(email: email, password: password)
                            } else {
                                viewModel.signIn(email: email, password: password)
                            }
                        }) {
                            Text(isRegistering ? "Зарегистрироваться" : "Войти")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            isRegistering.toggle()
                        }) {
                            Text(isRegistering ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                                //.foregroundColor(.gray)
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Button(action: {
                            showResetPassword = true
                        }) {
                            Text(isRegistering ? "" : "Сбросить пароль")
                                //.foregroundColor(.gray)
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
                    .onChange(of: viewModel.isAuthenticated) { newValue in
                        if newValue {
                            isLoggedIn = true // Переход при успешной авторизации
                        }
                    }
                }/*
                  .background(
                  LinearGradient(
                  gradient: Gradient(colors: [
                  Color(red: 6/255, green: 157/255, blue: 124/255), // #069d7c (светло-зелёный вверху)
                  Color(red: 5/255, green: 138/255, blue: 111/255), // #058a6f (средний зелёный)
                  Color(red: 0/255, green: 66/255, blue: 64/255)  // Светло-зелёный вверху
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                  )
                  )*/
            }
        }
    }
}

// Экран сброса пароля
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
