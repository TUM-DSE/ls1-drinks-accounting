//
//  KeychainHelper.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 02.01.23.
//

import Foundation

final class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    func save<T>(_ item: T, service: String, account: String) where T : Encodable {
        do {
            let data = try EncodingUtils.encoder.encode(item)
            save(data, service: service, account: account)
        } catch {
            assertionFailure("Fail to encode item for keychain: \(error)")
        }
    }
    
    func read<T>(service: String, account: String, type: T.Type) -> T? where T : Decodable {
        guard let data = read(service: service, account: account) else {
            return nil
        }

        do {
            let item = try EncodingUtils.decoder.decode(type, from: data)
            return item
        } catch {
            print(error)
//            assertionFailure("Failed to decode item for keychain: \(error)")
            return nil
        }
    }
    
    private func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        if status == errSecDuplicateItem {
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            
            SecItemUpdate(query, attributesToUpdate)
        }
    }
    
    private func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
