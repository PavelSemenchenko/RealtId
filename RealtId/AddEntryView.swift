//
//  AddEntryView.swift
//  RealtId
//
//  Created by Pavel Semenchenko on 24.03.2025.
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: CallerData
    let isEditing: Bool
    @Binding var entry: CallerEntry?
    
    @State private var phoneNumber: String = ""
    @State private var label: String = "Агент"
    @State private var isSpam: Bool = false
    
    var body: some View {
        NavigationStack { // Используем NavigationStack вместо NavigationView
            Form {
                TextField("Номер телефона (3801231234567)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                TextField("Метка (например, Агент)", text: $label)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Toggle("Спам", isOn: $isSpam)
            }
            .navigationTitle(isEditing ? "Редактировать запись" : "Добавить запись")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let normalizedNumber = data.normalizePhoneNumber(phoneNumber)
                        if isEditing, let existingEntry = entry {
                            let updatedEntry = CallerEntry(
                                id: existingEntry.id,
                                phoneNumber: normalizedNumber,
                                label: label,
                                isSpam: isSpam
                            )
                            data.deleteEntry(existingEntry)
                            data.addEntry(updatedEntry)
                            entry = nil
                        } else {
                            let newEntry = CallerEntry(
                                id: UUID().uuidString,
                                phoneNumber: normalizedNumber,
                                label: label,
                                isSpam: isSpam
                            )
                            data.addEntry(newEntry)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if isEditing, let currentEntry = entry {
                    phoneNumber = formatPhoneNumber(currentEntry.phoneNumber)
                    label = currentEntry.label
                    isSpam = currentEntry.isSpam
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        guard number.count >= 9 else { return number }
        let countryCode = String(number.prefix(3))
        let areaCode = String(number.dropFirst(3).prefix(2))
        let firstPart = String(number.dropFirst(5).prefix(3))
        let secondPart = String(number.dropFirst(8))
        return "+\(countryCode) (\(areaCode)) \(firstPart) \(secondPart)"
    }
}
