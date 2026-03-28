//
//  WeeklyStatisticsView.swift
//  LS1DrinksAccounting
//
//  Created by Codex on 28.03.26.
//

import SwiftUI
import Charts

public struct WeeklyStatisticsView: View {
    @StateObject
    private var viewModel: WeeklyStatisticsViewModel

    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    init(model: Model) {
        _viewModel = StateObject(wrappedValue: WeeklyStatisticsViewModel(model: model))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coffee Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Cumulative drinks from Monday to Sunday, updated hourly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 60)
                        Spacer()
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Could not load statistics", systemImage: "chart.xyaxis.line", description: Text(error))
                } else if let statistics = viewModel.statistics {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            SummaryCard(
                                title: statistics.current_week.title,
                                subtitle: statistics.current_week.range_label,
                                value: "\(statistics.current_week.total)",
                                accentColor: .orange
                            )
                            SummaryCard(
                                title: statistics.previous_week.title,
                                subtitle: statistics.previous_week.range_label,
                                value: "\(statistics.previous_week.total)",
                                accentColor: .gray
                            )
                        }

                        Chart(statistics.chartPoints) { point in
                            LineMark(
                                x: .value("Hour", point.slotIndex),
                                y: .value("Drinks", point.count)
                            )
                            .interpolationMethod(.stepEnd)
                            .lineStyle(
                                StrokeStyle(
                                    lineWidth: point.series == statistics.current_week.title ? 4 : 2,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .foregroundStyle(by: .value("Week", point.series))
                        }
                        .chartForegroundStyleScale([
                            statistics.current_week.title: Color.orange,
                            statistics.previous_week.title: Color.gray
                        ])
                        .chartXAxis {
                            AxisMarks(values: Array(stride(from: 0, through: 144, by: 24))) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel {
                                    if let slot = value.as(Int.self) {
                                        Text(statistics.current_week.points[slot].day_label)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYScale(domain: 0...statistics.maxCount)
                        .chartLegend(position: .top, alignment: .leading)
                        .frame(minHeight: 320)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(24)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .task {
            await viewModel.loadStatistics()
        }
        .onReceive(timer) { _ in
            Task {
                await viewModel.loadStatistics()
            }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let subtitle: String
    let value: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 999)
                .fill(accentColor)
                .frame(width: 32, height: 6)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("drinks")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

@MainActor
final class WeeklyStatisticsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var statistics: WeeklyDrinkStatsResponse?

    private let model: Model

    init(model: Model) {
        self.model = model
    }

    func loadStatistics() async {
        if isLoading {
            return
        }

        isLoading = true
        error = nil

        do {
            statistics = try await model.loadWeeklyDrinkStats()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

public struct WeeklyStatisticsChartPoint: Identifiable {
    let slotIndex: Int
    let count: Int
    let series: String

    public var id: String {
        "\(series)-\(slotIndex)"
    }
}

private extension WeeklyDrinkStatsResponse {
    var currentSlotIndex: Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let isoWeekday = (weekday + 5) % 7
        let hour = calendar.component(.hour, from: now)
        return min((isoWeekday * 24) + hour, max(current_week.points.count - 1, 0))
    }

    var maxCount: Int {
        max(
            current_week.points.prefix(currentSlotIndex + 1).map(\.count).max() ?? 0,
            previous_week.points.map(\.count).max() ?? 0,
            1
        )
    }

    var chartPoints: [WeeklyStatisticsChartPoint] {
        current_week.points.prefix(currentSlotIndex + 1).map {
            WeeklyStatisticsChartPoint(
                slotIndex: $0.slot_index,
                count: $0.count,
                series: current_week.title
            )
        } + previous_week.points.map {
            WeeklyStatisticsChartPoint(
                slotIndex: $0.slot_index,
                count: $0.count,
                series: previous_week.title
            )
        }
    }
}
