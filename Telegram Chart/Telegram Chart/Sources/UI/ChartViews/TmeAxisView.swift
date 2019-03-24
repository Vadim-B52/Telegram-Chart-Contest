//
// Created by Vadim on 2019-03-23.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisView: UIView {

    private var labels = [Int: UILabel]()
    private var removingLabels = [Int: UILabel]()

    private var timeAxisDescription: TimeAxisDescription?
    private var chart: DrawingChart?

    private lazy var formatter = ChartTextFormatter.shared
    private lazy var dateSize: CGSize = {
        let label = createLabel()
        label.sizeToFit()
        return label.bounds.size
    }()

    public var textColor: UIColor? {
        didSet {
            labels.forEach { $0.value.textColor = textColor }
            removingLabels.forEach { $0.value.textColor = textColor }
        }
    }

    public override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            if let chart = self.chart {
                updateDescription(chart: chart)
                rebuildLabels()
            }
        }
    }

    public func displayChart(chart: DrawingChart?, timeAxisDescription: TimeAxisDescription?) -> TimeAxisDescription? {
        self.chart = chart
        self.timeAxisDescription = timeAxisDescription
        if let chart = chart {
            updateDescription(chart: chart)
            rebuildLabels()
            setNeedsLayout()
        } else {
            remove(labels: labels)
            remove(labels: removingLabels)
            labels.removeAll()
            removingLabels.removeAll()
        }
        return self.timeAxisDescription
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let chart = chart else {
            return
        }
        updatePosition(labels: labels, chart: chart)
        updatePosition(labels: removingLabels, chart: chart)
    }

    private func remove(labels: [Int: UILabel]) {
        labels.forEach {
            $0.value.removeFromSuperview()
        }
    }

    private func updatePosition(labels: [Int: UILabel], chart: DrawingChart) {
        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        for (timeIdx, label) in labels {
            let timestamp = chart.timestamps[timeIdx]
            label.sizeToFit()
            label.center = CGPoint(x: calc.x(in: bounds, timestamp: timestamp), y: bounds.midY)
        }
    }

    private func rebuildLabels() {
        guard let chart = chart, let description = timeAxisDescription else {
            return
        }

        var existing = Set<Int>()
        labels.forEach { existing.insert($0.key) }

        var current = Set<Int>()
        let n = min(chart.indexRange.endIdx, chart.timestamps.count - 1)
        for i in stride(from: description.zeroIdx, through: n, by: description.step) {
            current.insert(i)
        }

        let toRemove = existing.subtracting(current)
        var toRemoveLabels = [UILabel]()
        toRemove.forEach { timeIdx in
            let label = labels[timeIdx]!
            toRemoveLabels.append(label)
            removingLabels[timeIdx] = label
            labels[timeIdx] = nil
        }

        let toInsert = current.subtracting(existing)
        var toInsetLabels = [UILabel]()
        toInsert.forEach { timeIdx in
            let label = createLabel()
            addSubview(label)
            label.alpha = 0

            let timestamp = chart.timestamps[timeIdx]
            let str = formatter.axisDateText(timestamp: timestamp)
            label.text = str

            labels[timeIdx] = label
            toInsetLabels.append(label)
        }

        UIView.animate(withDuration: 0.3, animations: {
            toRemoveLabels.forEach { $0.alpha = 0 }
            toInsetLabels.forEach { $0.alpha = 1 }
        }, completion: { b in
            toRemoveLabels.forEach { $0.removeFromSuperview() }
        })
    }

    private func updateDescription(chart: DrawingChart) {
        guard !bounds.isEmpty else {
            return
        }
        let rect = bounds
        let calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        var currDescr: TimeAxisDescription
        var dateSize = self.dateSize
        dateSize.width += 10
        if let prevDescr = timeAxisDescription {
            currDescr = prevDescr

            let c1 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx])
            let c2 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx + prevDescr.step])
            if c2 - c1 > 2 * dateSize.width {
                currDescr.step = prevDescr.step / 2
            } else if c2 - c1 < dateSize.width {
                currDescr.step = prevDescr.step * 2
            }

            var newZero = currDescr.zeroIdx
            while newZero >= chart.indexRange.startIdx {
                newZero -= currDescr.step
            }
            currDescr.zeroIdx = newZero + currDescr.step
        } else {
            let zeroIdx = chart.closestIdxTo(timestamp: calculator.timestampAt(x: dateSize.width / 2, rect: rect))
            let zeroTime = chart.timestamps[zeroIdx]
            var step = 1
            while true {
                let c1 = calculator.x(in: rect, timestamp: zeroTime)
                let c2 = calculator.x(in: rect, timestamp: chart.timestamps[zeroIdx + step])
                if c2 - c1 < dateSize.width {
                    step *= 2
                } else {
                    break
                }
            }
            currDescr = TimeAxisDescription(zeroIdx: zeroIdx, step: step)
        }
        self.timeAxisDescription = currDescr
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.text = formatter.sizingString
        label.textColor = textColor
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        return label
    }
}
