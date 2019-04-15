//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class DrawingChart {
    private var valueRangeCache = [Chart.Plot.Identifier: ValueRange]()
    private var yAxisCache = [Chart.Plot.Identifier: YAxisCalculationResult]()
    public let chart: Chart
    public let enabledPlotId: Set<Chart.Plot.Identifier>
    public let timestamps: [Chart.Time]
    public let timeRange: TimeRange
    public let timeIndexRange: TimeIndexRange
    public let valueRangeCalculation: ValueRangeCalculation
    public let yAxisCalculation: YAxisCalculation

    public init(chart: Chart,
                enabledPlotId: Set<String>,
                timestamps: [Chart.Time],
                timeRange tr: TimeRange? = nil,
                valueRangeCalculation: ValueRangeCalculation,
                yAxisCalculation: YAxisCalculation) {

        self.chart = chart
        self.enabledPlotId = enabledPlotId
        self.timestamps = timestamps
        let timeRange = tr ?? chart.timeRange
        self.timeRange = timeRange
        self.valueRangeCalculation = valueRangeCalculation
        self.yAxisCalculation = yAxisCalculation

        timeIndexRange = TimeIndexRange(
                startIdx: DrawingChart.closestIdxTo(timestamp: timeRange.min, timestamps: timestamps),
                endIdx: DrawingChart.closestIdxTo(timestamp: timeRange.max, timestamps: timestamps))
    }

    public var allPlots: [Chart.Plot] {
        return chart.plots
    }

    public private(set) lazy var visiblePlots: [Chart.Plot] = {
        allPlots.filter { enabledPlotId.contains($0.identifier) }
    }()

    private func rawValueRange(plot: Chart.Plot) -> ValueRange {
        if let vr = valueRangeCache[plot.identifier] {
            return vr
        }
        let vr = valueRangeCalculation.valueRange(plot: plot, visiblePlots: visiblePlots, indexRange: timeIndexRange)
        valueRangeCache[plot.identifier] = vr
        return vr
    }

    private func yAxis(plot: Chart.Plot) -> YAxisCalculationResult {
        if let r = yAxisCache[plot.identifier] {
            return r
        }
        let r = yAxisCalculation.yAxis(valueRange: rawValueRange(plot: plot))
        yAxisCache[plot.identifier] = r
        return r
    }

    public func valueRange(plot: Chart.Plot) -> ValueRange {
        return yAxis(plot: plot).valueRange
    }

    public func axisValues(plot: Chart.Plot) -> YAxisValues {
        return yAxis(plot: plot).yAxisValues
    }

    public func isPlotVisible(_ plot: Chart.Plot) -> Bool {
        return enabledPlotId.contains(plot.identifier)
    }

    public func closestIdxTo(timestamp: Int64) -> Int {
        return DrawingChart.closestIdxTo(timestamp: timestamp, timestamps: timestamps)
    }

    public static func closestIdxTo(timestamp: Int64, timestamps: [Int64]) -> Int {
        var low = 0
        var high = timestamps.count - 1
        while low != high {
            let mid = low + (high - low) / 2
            if timestamps[mid] <= timestamp && timestamp <= timestamps[mid + 1] {
                if timestamp - timestamps[mid] < timestamps[mid + 1] - timestamp {
                    return mid
                } else {
                    return mid + 1
                }
            }
            if timestamps[mid] < timestamp {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    public struct XCalculator {
        public let timeRange: TimeRange

        public func x(in rect: CGRect, timestamp: Int64) -> CGFloat {
            let d = timestamp - timeRange.min
            let t = CGFloat(d) / CGFloat(timeRange.size)
            let x = rect.width * t
            return rect.minX + x
        }

        public func timestampAt(x: CGFloat, rect: CGRect) -> Int64 {
            let d = (x - rect.minX) / rect.width
            let ts = CGFloat(timeRange.size) * d
            return timeRange.min + Int64(ts)
        }
    }

    public struct YCalculator {
        public let valueRange: ValueRange

        public func y(in rect: CGRect, value: Int64) -> CGFloat {
            let d = value - valueRange.min
            let v = CGFloat(d) / CGFloat(valueRange.size)
            let y = rect.size.height * v
            return rect.maxY - y
        }
    }

    public struct StackedYCalculator {
        private let calc: YCalculator
        public let plots: [Chart.Plot]
        public let plotIdx: Int

        public init(valueRange: ValueRange, plots: [Chart.Plot], plotIdx: Int) {
            self.plots = plots
            self.plotIdx = plotIdx
            calc = YCalculator(valueRange: valueRange)
        }

        public func y(in rect: CGRect, at idx: Int) -> CGFloat {
            var value = Chart.Value.zero
            for i in 0...plotIdx {
                value += plots[i].values[idx]
            }
            return calc.y(in: rect, value: value)
        }

        public func allValueAt(_ idx: Int) -> Chart.Value {
            var value = Chart.Value.zero
            for plot in plots {
                value += plot.values[idx]
            }
            return value
        }
    }

    public struct PercentageStackedYCalculator {
        public let plots: [Chart.Plot]
        public let plotIdx: Int

        public func y(in rect: CGRect, at idx: Int) -> CGFloat {
            var idxValue = Chart.Value.zero
            for i in 0...plotIdx {
                idxValue += plots[i].values[idx]
            }
            var value100 = idxValue
            var i = plotIdx + 1
            let n = plots.count
            while i < n {
                value100 += plots[i].values[idx]
                i += 1
            }
            let calc = YCalculator(valueRange: ValueRange(min: 0, max: value100))
            return calc.y(in: rect, value: idxValue)
        }
    }

    public struct PointCalculator {
        public let timeRange: TimeRange
        public let valueRange: ValueRange

        public func pointAtTimestamp(_ timestamp: Int64, value: Int64, rect: CGRect) -> CGPoint {
            let xCalc = XCalculator(timeRange: timeRange)
            let yCalc = YCalculator(valueRange: valueRange)
            let x = xCalc.x(in: rect, timestamp: timestamp)
            let y = yCalc.y(in: rect, value: value)
            return CGPoint(x: x, y: y)
        }
    }
}

public protocol ValueRangeCalculation {
    func valueRange(plot: Chart.Plot, visiblePlots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange
}

public protocol YAxisCalculation {
    func yAxis(valueRange: ValueRange) -> YAxisCalculationResult
}

public struct YAxisCalculationResult {
    let valueRange: ValueRange
    let yAxisValues: YAxisValues
}

public struct YAxisValues {
    public let zero: Chart.Value
    public let step: Chart.Value

    public static let no = YAxisValues(zero: -1, step: -1)
}

public struct TimeAxisDescription: Equatable {
    public var zeroIdx: Int
    public var step: Int
}

public struct ValueRangeNoYAxisStrategy: YAxisCalculation {
    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        return YAxisCalculationResult(valueRange: valueRange, yAxisValues: .no)
    }
}

public struct ValueRangeHasStaticYAxis: YAxisCalculation {
    public static let percentage: YAxisCalculation = ValueRangeHasStaticYAxis(
            valueRange: .percentage,
            yAxisValues: YAxisValues(zero: 0, step: 25))

    public let valueRange: ValueRange
    public let yAxisValues: YAxisValues
    
    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        return YAxisCalculationResult(valueRange: valueRange, yAxisValues: yAxisValues)
    }
}

public struct ValueRangePrettyYAxis: YAxisCalculation {

    private static let pows = [
        1,
        1_0,
        1_00,
        1_000,
        1_000_0,
        1_000_00,
        1_000_000,
        1_000_000_0,
        1_000_000_00,
        1_000_000_000,
    ]

    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        let sz = valueRange.max
        var p = 0
        let n = 4
        let ds = sz / Int64(n)
        let pows = ValueRangePrettyYAxis.pows
        while ds > pows[p] {
            p += 1
        }
        let step: Int64
        if p > 1 {
            let t = pow(10.0, Double(p - 1))
            step = Int64(round(Double(ds) / t) * t)
        } else {
            step = max(1, sz / Int64(n))
        }
        return YAxisCalculationResult(
                valueRange: ValueRange(min: 0, max: valueRange.max + step / 4),
                yAxisValues: YAxisValues(zero: 0, step: step))
    }
}

public struct ValueRangePrettyScaledYAxis: YAxisCalculation {

    private static let pows = [
        1,
        1_0,
        1_00,
        1_000,
        1_000_0,
        1_000_00,
        1_000_000,
        1_000_000_0,
        1_000_000_00,
        1_000_000_000,
    ]

    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        let sz = valueRange.size
        var p = 0
        let n = 4
        let ds = sz / Int64(n)
        let pows = ValueRangePrettyScaledYAxis.pows
        while ds > pows[p] {
            p += 1
        }
        let step: Int64
        if p > 1 {
            let t = pow(10.0, Double(p - 1))
            step = Int64(round(Double(ds) / t) * t)
        } else {
            step = max(1, sz / Int64(n))
        }
        let zero = valueRange.min / step * step
        return YAxisCalculationResult(
                valueRange: ValueRange(min: min(valueRange.min, zero), max: valueRange.max + step / 4),
                yAxisValues: YAxisValues(zero: zero, step: step))
    }
}

public struct ValueRangeExactYAxis: YAxisCalculation {
    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        let step: Int64 = valueRange.size / 4
        return YAxisCalculationResult(
                valueRange: ValueRange(min: max(0, valueRange.min - step / 4), max: valueRange.max + step / 4),
                yAxisValues: YAxisValues(zero: valueRange.min, step: step))
    }
}

public struct StaticValueRangeCalculation: ValueRangeCalculation {

    public static let percentage = StaticValueRangeCalculation(valueRange: .percentage)

    public let valueRange: ValueRange

    public func valueRange(plot: Chart.Plot, visiblePlots plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        return valueRange
    }
}

public struct FullValueRangeCalculation: ValueRangeCalculation {
    public func valueRange(plot: Chart.Plot, visiblePlots plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        return ValueRange(ranges: plots.map { $0.valueRange } )
    }
}

public struct SelectedValueRangeCalculation: ValueRangeCalculation {
    public func valueRange(plot: Chart.Plot, visiblePlots plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        let ranges = plots.map { $0.valueRange(indexRange: indexRange) }
        return ValueRange(ranges: ranges)
    }
}

public struct YScaledValueRangeCalculation: ValueRangeCalculation {
    public let internalCalculation: ValueRangeCalculation

    public func valueRange(plot: Chart.Plot, visiblePlots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        let vr = internalCalculation.valueRange(plot: plot, visiblePlots: [plot], indexRange: indexRange)
        return ValueRange(min: vr.min, max: vr.max)
    }
}

public struct StackedValueRangeCalculation: ValueRangeCalculation {
    public func valueRange(plot: Chart.Plot, visiblePlots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        var i = indexRange.startIdx
        var max = Chart.Value.zero
        while i <= indexRange.endIdx {
            var m = Chart.Value.zero
            var j = 0
            let n = visiblePlots.count
            while j < n {
                let plot = visiblePlots[j]
                m += plot.values[i]
                j += 1
            }
            if m > max {
                max = m
            }
            i += 1
        }
        // TODO: assumption non negative values
        return ValueRange(min: 0, max: max)
    }
}

public struct VolumeStyleValueRangeCalculation: ValueRangeCalculation {
    public let internalCalculation: ValueRangeCalculation

    public func valueRange(plot: Chart.Plot, visiblePlots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        let vr = internalCalculation.valueRange(plot: plot, visiblePlots: visiblePlots, indexRange: indexRange)
        // TODO: assumption 0 is min
        return ValueRange(min: 0, max: vr.max)
    }
}
