//
//  ChartListScreen.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartListScreen {
    
    public let charts: [Chart]
    public let chartStates: [ChartState]
    public let errorText: String?
    public private(set) var isNightModeEnabled = false

    public init() {
        let client = ChartClient()
        let charts: [Chart]
        let errorText: String?
        do {
            charts = try client.loadChartData()
            errorText = nil
        } catch {
            charts = []
            errorText = NSLocalizedString("Something went wrong", comment: "")
        }
        self.charts = charts
        self.errorText = errorText
        self.chartStates = charts.map({ (chart) -> ChartState in
            return ChartState(enabledPlotId: Set(chart.plots.map { $0.identifier }))
        })
    }
    
    public func switchMode() {
        isNightModeEnabled = !isNightModeEnabled
    }
 
    public func dataAt(_ idx: Int) -> (Chart, ChartState) {
        return (charts[idx], chartStates[idx])
    }
}

public struct ChartState {
    public let enabledPlotId: Set<String>
}
