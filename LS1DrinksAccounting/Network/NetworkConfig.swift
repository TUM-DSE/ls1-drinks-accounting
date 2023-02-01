//
//  NetworkConfig.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

struct NetworkConfig {
    let baseUrl: String
    let decoder: JSONDecoder
    let encoder: JSONEncoder
}
