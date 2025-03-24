//
//  CallDirectoryHandler.swift
//  AgentsExtention
//
//  Created by Pavel Semenchenko on 26.02.2025.
//

import Foundation
import CallKit

struct CallerEntry: Codable {
    var id: String
    var phoneNumber: String
    var label: String
    var isSpam: Bool
}

class CallDirectoryHandler: CXCallDirectoryProvider {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        let entries = loadEntriesFromAppGroup()
        
        for entry in entries {
            if let phoneNumber = CXCallDirectoryPhoneNumber(entry.phoneNumber) {
                if entry.isSpam {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
                } else {
                    context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: entry.label)
                }
            }
        }
        
        context.completeRequest()
    }
    
    private func loadEntriesFromAppGroup() -> [CallerEntry] {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.yourdomain.RealtId"),
           let data = sharedDefaults.data(forKey: "callerEntries"),
           let decoded = try? JSONDecoder().decode([CallerEntry].self, from: data) {
            return decoded
        }
        return []
    }
}

extension CXCallDirectoryPhoneNumber {
    init?(_ string: String) {
        guard let number = Int64(string) else { return nil }
        self = number
    }
}

