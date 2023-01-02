//
//  AuthApi.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 30.12.22.
//

import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct AuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let validUntil: Date
    
    private enum CodingKeys : String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case validUntil = "valid_until"
    }
    
    var isValid: Bool {
        validUntil > Date()
    }
}

class AuthApi {
    let config: NetworkConfig
    
    init (_ config: NetworkConfig) {
        self.config = config
    }
    
    /// Logs in and returns the access token, or null
    func login(username: String, password: String) async throws -> AuthToken? {
        guard let url = URL(string: "\(config.baseUrl)/api/auth/login") else {
            throw NetworkError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(LoginRequest(username: username, password: password)))
        
        guard let response = response as? HTTPURLResponse else {
            return nil
        }
        
        if response.statusCode != 200 {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)

                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                return Date()
            })
            //print(String(data: data, encoding: .utf8))
            let loginResponse = try decoder.decode(AuthToken.self, from: data)
            
            return loginResponse
        } catch {
            print(String(describing: error))
            throw error
        }
    }
}
