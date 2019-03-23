//
// Created by Vadim on 2019-03-23.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisView: UIView {

    private var labels = [UILabel]()
    public var timeAxisDescription: TimeAxisDescription?

    private lazy var formatter = ChartTextFormatter.shared
    private lazy var options = NSStringDrawingOptions.usesLineFragmentOrigin
//  TODO:  private lazy var attributes: // [NSAttributedString.Key: Any]? = [NSAttributedString.Key.foregroundColor: config.textColor]

    public override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            rebuildLabels()
            updateDescription()
            updateLabelVisibility(animated: false)
        }
    }

    public var chart: DrawingChart? {
        didSet {
            updateDescription()
            setNeedsLayout()
            updateLabelVisibility(animated: true)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let chart = chart,
              let description = timeAxisDescription else {

            return
        }

        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        var visitedActiveLabels = 0

        for i in 0..<labels.count {
            let timestamps = chart.timestamps
            let timeIdx: Int
            if i % 2 == 0 {
                timeIdx = description.zeroIdx + visitedActiveLabels * description.step
                visitedActiveLabels += 1
            } else {
                let timeIdx1 = description.zeroIdx + (visitedActiveLabels - 1) * description.step
                let timeIdx2 = description.zeroIdx + visitedActiveLabels * description.step
                timeIdx = timeIdx1 + Int(Double(timeIdx2 - timeIdx1) / 2)
            }

            let label = labels[i]
            if timeIdx < timestamps.count {
                let timestamp = timestamps[timeIdx]
                // TODO: do not update text here
                label.text = formatter.axisDateText(timestamp: timestamp)
                label.sizeToFit()
                let x = calc.x(in: bounds, timestamp: timestamp)
                let y = bounds.midY
                label.center = CGPoint(x: x, y: y)
                label.isHidden = false
            } else {
                label.isHidden = true
            }
        }
    }

    private func updateLabelVisibility(animated: Bool) {
        guard let chart = chart,
              let description = timeAxisDescription else {

            return
        }

        let labels = self.labels
        var visitedActiveLabels = 0

        UIView.animate(withDuration: animated ? 0.3 : 0) {
            for i in 0..<labels.count {
                let label = labels[i]
                let timestamps = chart.timestamps
                let timeIdx: Int
                if i % 2 == 0 {
                    timeIdx = description.zeroIdx + visitedActiveLabels * description.step
                    visitedActiveLabels += 1
                    label.alpha = 1
                } else {
                    let timeIdx1 = description.zeroIdx + (visitedActiveLabels - 1) * description.step
                    let timeIdx2 = description.zeroIdx + visitedActiveLabels * description.step
                    timeIdx = timeIdx1 + Int(Double(timeIdx2 - timeIdx1) / 2)
                    label.alpha = 0
                }
                if timeIdx >= timestamps.count {
                    label.alpha = 0
                    break
                }
            }
        }
    }

    private func updatePosition(label: UILabel, idx: Int, chart: DrawingChart) {
        label.sizeToFit()
        let calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let x = calculator.x(in: bounds, timestamp: chart.timestamps[idx])
        let y = bounds.midY
        label.center = CGPoint(x: x, y: y)
    }

    private func rebuildLabels() {
        guard !bounds.isEmpty else {
            return
        }
        let dateSize = self.dateSize()
        let count = Int(ceil(bounds.width / dateSize.width))
        if labels.count != count {
            labels.forEach { $0.removeFromSuperview() }
            labels.removeAll()
            for _ in 0..<count {
                let label = UILabel()
                label.text = "FFF 99" // TODO;
                addSubview(label)
                labels.append(label)
            }
        }
    }

    private func updateDescription() {
        guard let chart = chart, !bounds.isEmpty else {
            return
        }
        let dateSize = self.dateSize()
        let rect = bounds
        let calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        var currDescr: TimeAxisDescription
        if let prevDescr = timeAxisDescription {
            currDescr = prevDescr

            let c1 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx])
            let c2 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx + prevDescr.step])
            if c2 - c1 > 3 * dateSize.width {
                currDescr.step = prevDescr.step / 2
            } else if c2 - c1 < 1.5 * dateSize.width {
                currDescr.step = prevDescr.step * 2
            }

            var i = currDescr.zeroIdx
            while i >= chart.indexRange.startIdx {
                i -= currDescr.step
            }
            currDescr.zeroIdx = i + currDescr.step
        } else {
            let zeroIdx = chart.closestIdxTo(timestamp: calculator.timestampAt(x: 10 + dateSize.width / 2, rect: rect))
            let zeroTime = chart.timestamps[zeroIdx]
            var step = 1
            while true {
                let c1 = calculator.x(in: rect, timestamp: zeroTime)
                let c2 = calculator.x(in: rect, timestamp: chart.timestamps[zeroIdx + step])
                if c2 - c1 < 1.5 * dateSize.width {
                    step *= 2
                } else {
                    break
                }
            }
            currDescr = TimeAxisDescription(zeroIdx: zeroIdx, step: step)
        }
        self.timeAxisDescription = currDescr
    }

    private func dateSize() -> CGSize {
        return formatter.sizingString.boundingRect(
                with: bounds.size,
                options: options,
                attributes: nil,
//                attributes: attributes,
                context: nil).size
    }
}
