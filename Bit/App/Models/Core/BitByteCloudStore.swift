//
//  BitByteCloudStore.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation

class BitByteCloudStore {
    static let shared = BitByteCloudStore()
    private let store = NSUbiquitousKeyValueStore.default
    private var isInitialized = false

    private init() {
        print("BitByteCloudStore initializing...")
        // Make sure the store is ready before we use it
        initializeStore()
    }

    private func initializeStore() {
        // Try to synchronize first
        let success = store.synchronize()
        print("BitByteCloudStore initialized, synchronize result: \(success)")
        isInitialized = true
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    @objc private func storeDidChange(_ notification: Notification) {
        print("iCloud KVStore changed externally")
        store.synchronize()
    }

    func setValue(_ value: Any?, forKey key: String) {
        guard isInitialized else { return }
        store.set(value, forKey: key)
        store.synchronize()
    }

    func getValue(forKey key: String) -> Any? {
        guard isInitialized else { return nil }
        return store.object(forKey: key)
    }

    func removeValue(forKey key: String) {
        guard isInitialized else { return }
        store.removeObject(forKey: key)
        store.synchronize()
    }

    func synchronize() -> Bool {
        return store.synchronize()
    }
}