//
//  AddEntryView.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//

import SwiftUI

// Экран добавления новой записи
struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: CallerData
    @State private var phoneNumber = ""
    @State private var label = "Агент"
    @State private var isSpam = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Номер телефона (3801231234567)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Метка (например, Агент)", text: $label)
                Toggle("Спам", isOn: $isSpam)
            }
            .navigationTitle("Добавить запись")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
                        let newEntry = CallerEntry(
                            id: UUID().uuidString, // Временный ID
                            phoneNumber: normalizedNumber,
                            label: label,
                            isSpam: isSpam
                        )
                        data.addEntry(newEntry)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let previewData = CallerData()
    return AddEntryView(data: previewData)
}
