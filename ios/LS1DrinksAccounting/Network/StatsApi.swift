//
//  StatsApi.swift
//  LS1DrinksAccounting
//
//  Created by Codex on 28.03.26.
//

import Foundation

struct WeeklyDrinkStatsPoint: Codable {
    let slot_index: Int
    let day_label: String
    let count: Int
}

struct WeeklyDrinkStatsSeries: Codable {
    let title: String
    let range_label: String
    let total: Int
    let points: [WeeklyDrinkStatsPoint]
}

struct WeeklyDrinkStatsResponse: Codable {
    let generated_at: Date
    let current_week: WeeklyDrinkStatsSeries
    let previous_week: WeeklyDrinkStatsSeries
}

class StatsApi {
    let networking: Networking

    init(_ networking: Networking) {
        self.networking = networking
    }

    func getWeeklyDrinkStats() async throws -> WeeklyDrinkStatsResponse {
        guard let request = try await networking.get(path: "/api/stats/weekly_drinks", authorized: false) else {
            throw NetworkError.invalidUrl
        }

        let data = try await URLSession.shared.data(for: request)

        return try networking.config.decoder.decode(WeeklyDrinkStatsResponse.self, from: data.0)
    }
}
