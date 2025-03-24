
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CallKit


// Главный экран приложения
struct ContentView: View {
    @StateObject private var data = CallerData()
    @StateObject private var loginVM = LoginVM()
    @State private var showingAddView = false
    @State private var showingSplash = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(data.entries) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.label)
                            .font(.headline)
                        Text(formatPhoneNumber(entry.phoneNumber))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if entry.isSpam {
                            Text("Спам")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .padding(.top, -80)
            .navigationTitle("Realt Id").font(.headline)
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Image(systemName: "person.badge.shield.checkmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loginVM.signOut()
                        showingSplash = true
                    }) {
                        //Text("Выход")
                        Image(systemName: "xmark.circle")
                    }
                }
                
            }
            .sheet(isPresented: $showingAddView) {
                AddEntryView(data: data)
            }
            .fullScreenCover(isPresented: $showingSplash) {
                SplashScreen()
            }
        }
    }
    
    // Функция удаления записи
    private func deleteEntries(at offsets: IndexSet) {
        offsets.forEach { index in
            let entry = data.entries[index]
            data.deleteEntry(entry)
        }
    }
    
    // Форматирование номера для отображения
    private func formatPhoneNumber(_ number: String) -> String {
        guard number.count >= 9 else { return number }
        let countryCode = String(number.prefix(3))
        let areaCode = String(number.dropFirst(3).prefix(2))
        let firstPart = String(number.dropFirst(5).prefix(3))
        let secondPart = String(number.dropFirst(8))
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
}



#Preview {
    ContentView()
}
