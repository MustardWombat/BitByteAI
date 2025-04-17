//
//  CurrencyModel.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine
import CloudKit

class CurrencyModel: ObservableObject {
    @Published var balance: Int = 0

    private let recordID = CKRecord.ID(recordName: "UserCurrency")
    private let recordType = "Currency"

    init() {
        fetchFromCloudKit()
    }

    func earn(amount: Int) {
        balance += amount
        saveToCloudKit()
    }

    func deposit(_ amount: Int) {
        balance += amount
        saveToCloudKit()
    }

    // --- CloudKit Sync ---
    func saveToCloudKit() {
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["balance"] = balance as CKRecordValue

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                print("CloudKit save error: \(error)")
            } else {
                self.fetchFromCloudKit() // Refresh after save
            }
        }
    }

    func fetchFromCloudKit() {
        CKContainer.default().privateCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record, let cloudBalance = record["balance"] as? Int {
                DispatchQueue.main.async {
                    self.balance = cloudBalance
                }
            } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                // Record does not exist, create it
                DispatchQueue.main.async {
                    self.balance = 0
                    self.saveToCloudKit()
                }
            } else if let error = error {
                print("CloudKit fetch error: \(error)")
            }
        }
    }
}
