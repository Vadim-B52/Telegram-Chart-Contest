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
    public private(set) var chartStates: [ChartState]
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
            let enabledIds = Set(chart.plots.map { $0.identifier })
            return ChartState(enabledPlotId: enabledIds, selectedTimeRange: nil)
        })
    }
    
    public func switchMode() {
        isNightModeEnabled = !isNightModeEnabled
    }
 
    public func dataAt(_ idx: Int) -> (chart: Chart, state: ChartState) {
        return (charts[idx], chartStates[idx])
    }

    public func updateSelectedTimeRange(_ timeRange: TimeRange, at idx: Int) {
        chartStates[idx] = chartStates[idx].byChanging(selectedTimeRange: timeRange)
    }

    public func canChangeVisibilityForChartAt(_ idx: Int, plotIndex: Int) -> Bool {
        let (chart, state) = dataAt(idx)
        let plotId = chart.plots[plotIndex].identifier
        if state.enabledPlotId.contains(plotId) {
            return state.enabledPlotId.count > 1
        } else {
            return true
        }
    }

    public func changeVisibilityForChartAt(_ idx: Int, plotIndex: Int) {
        let (chart, state) = dataAt(idx)
        let plotId = chart.plots[plotIndex].identifier
        if state.enabledPlotId.contains(plotId) {
            chartStates[idx] = state.byDisablingPlot(identifier: plotId)
        } else {
            chartStates[idx] = state.byEnablingPlot(identifier: plotId)
        }
    }

    public func updateState(_ state: ChartState, at idx: Int) {
        chartStates[idx] = state
    }
}

public struct ChartState {

    public let enabledPlotId: Set<String>
    public let selectedTimeRange: TimeRange?

    public func byChanging(selectedTimeRange: TimeRange?) -> ChartState {
        return ChartState(enabledPlotId: enabledPlotId, selectedTimeRange: selectedTimeRange)
    }

    public func byTurningPlot(identifier: String) -> ChartState {
        if enabledPlotId.contains(identifier) {
            return byDisablingPlot(identifier: identifier)
        }
        return byEnablingPlot(identifier: identifier)
    }

    public func bySingleEnabling(identifier: String) -> ChartState {
        return ChartState(enabledPlotId: [identifier], selectedTimeRange: selectedTimeRange)
    }

    public func byEnablingPlot(identifier: String) -> ChartState {
        return ChartState(enabledPlotId: enabledPlotId.union([identifier]), selectedTimeRange: selectedTimeRange)
    }

    public func byDisablingPlot(identifier: String) -> ChartState {
        return ChartState(enabledPlotId: enabledPlotId.subtracting([identifier]), selectedTimeRange: selectedTimeRange)
    }
}
