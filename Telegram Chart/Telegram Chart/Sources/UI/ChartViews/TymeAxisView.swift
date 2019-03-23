//
// Created by Vadim on 2019-03-23.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisView: UIView {

    private var widerLabels = [UILabel]()
    private var labels = [UILabel]()
    private var closerLabels = [UILabel]()

    public var timeAxisDescription: TimeAxisDescription?

    private lazy var formatter = ChartTextFormatter.shared
    private lazy var options = NSStringDrawingOptions.usesLineFragmentOrigin

    public override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            let description = timeAxisDescription
            updateDescription()
            rebuildLabels(description)
            updateLabelVisibility(animated: false)
        }
    }

    public var chart: DrawingChart? {
        didSet {
            let description = timeAxisDescription
            updateDescription()
            rebuildLabels(description)
            setNeedsLayout()
//            updateLabelVisibility(animated: true)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let chart = chart,
              let description = timeAxisDescription else {

            return
        }

        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)

        let x0 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx])
        let x1 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx + description.step])
        let spacing = x1 - x0
        let y = bounds.midY
        let halfSpacing = spacing / 2
        let doubleSpacing = spacing * 2

        for (idx, label) in labels.enumerated() {
            let x = x0 + spacing * CGFloat(idx)
            let ts = calc.timestampAt(x: x, rect: bounds)
            label.text = formatter.axisDateText(timestamp: ts)
            label.sizeToFit()
            label.center = CGPoint(x: x, y: y)
        }

        for (idx, label) in widerLabels.enumerated() {
            let x = x0 + doubleSpacing * CGFloat(idx)
            let ts = calc.timestampAt(x: x, rect: bounds)
            label.text = formatter.axisDateText(timestamp: ts)
            label.sizeToFit()
            label.center = CGPoint(x: x, y: y)
        }

        for (idx, label) in closerLabels.enumerated() {
            let x = x0 + halfSpacing * CGFloat(idx)
            let ts = calc.timestampAt(x: x, rect: bounds)
            label.text = formatter.axisDateText(timestamp: ts)
            label.sizeToFit()
            label.center = CGPoint(x: x, y: y)
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

    private func rebuildLabels(_ prevDescr: TimeAxisDescription?) {
        guard !bounds.isEmpty, let chart = chart, let description = timeAxisDescription else {
            return
        }

        let getLabel: () -> UILabel = {
            let label = UILabel()
            label.text = "FFF 99"
            label.alpha = 0
            self.addSubview(label)
            return label
        }

        if prevDescr == nil {
            let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
            let x1 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx])
            let x2 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx + description.step])
            let spacing = (x2 - x1) / 2
            let count = Int(ceil(bounds.width / spacing))

            closerLabels.forEach { $0.removeFromSuperview() }

            closerLabels.removeAll()
            widerLabels.removeAll()
            labels.removeAll()

            for i in 0..<count {
                let label = getLabel()
                closerLabels.append(label)
                if i % 2 == 0 {
                    labels.append(label)
                    label.alpha = 1
                }
                if i % 4 == 0 {
                    labels.append(label)
                }
            }

            return
        }

        let descr = prevDescr!
        if descr.step < description.step {
            // TODO: perfomans! n^2
            let toRemove = closerLabels.filter { !widerLabels.contains($0) }
            labels = widerLabels
            closerLabels.removeAll()
            widerLabels.removeAll()

            for (idx, label) in labels.enumerated() {
                if idx % 2 == 0 {
                    widerLabels.append(label)
                }
                closerLabels.append(label)
                closerLabels.append(getLabel())
            }

            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                toRemove.forEach { $0.alpha = 0 }
            }, completion: { b in
                toRemove.forEach { $0.removeFromSuperview() }
            })
        } else if descr.step > description.step {
            labels = closerLabels

            closerLabels.removeAll()
            widerLabels.removeAll()

            for (idx, label) in labels.enumerated() {
                if idx % 2 == 0 {
                    widerLabels.append(label)
                }
                closerLabels.append(label)
                closerLabels.append(getLabel())
            }

            UIView.animate(withDuration: 0.3, animations: { [labels] () -> Void in
                labels.forEach { $0.alpha = 1 }
            }, completion: { b in
//                toRemove.forEach { $0.removeFromSuperview() }
            })
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
