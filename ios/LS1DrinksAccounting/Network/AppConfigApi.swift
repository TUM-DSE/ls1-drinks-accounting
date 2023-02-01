//
//  AppConfigApi.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 25.01.23.
//

import Foundation

class AppConfigApi {
    let networking: Networking
    
    init(_ networking: Networking) {
        self.networking = networking
    }

    func isLatestAppVersion(version: String) async throws -> Bool {
        guard let request = try await networking.get(path: "/api/config/app/\(version)/is_latest", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.data(for: request)
        
        let result = try networking.config.decoder.decode(Bool.self, from: data.0)
        
        return result
    }
}
