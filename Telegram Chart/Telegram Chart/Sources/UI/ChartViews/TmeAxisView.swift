//
// Created by Vadim on 2019-03-23.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisView: UIView {

    private var widerLabels = [UILabel]()
    private var labels = [UILabel]()
    private var closerLabels = [UILabel]()

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
            closerLabels.forEach { $0.textColor = textColor }
        }
    }

    public override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            let description = timeAxisDescription
            updateDescription()
            rebuildLabels(description)
        }
    }

    public func displayChart(chart: DrawingChart?, timeAxisDescription: TimeAxisDescription?) -> TimeAxisDescription? {
        let description = self.timeAxisDescription
        self.chart = chart
        self.timeAxisDescription = timeAxisDescription
        updateDescription()
        rebuildLabels(description)
        setNeedsLayout()
        return self.timeAxisDescription
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let chart = chart,
              let description = timeAxisDescription else {

            return
        }

        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
//        let x0 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx])
//        let x1 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx + description.step])
//        let halfSpacing = (x1 - x0) / 2
        let y = bounds.midY

//        var i: CGFloat = -1
//        closerLabels.forEach { label in
//            let x = x0 + halfSpacing * i
//            i += 1
//            let ts = calc.timestampAt(x: x, rect: bounds)
//            label.text = formatter.axisDateText(timestamp: ts)
//            label.sizeToFit()
//            label.center = CGPoint(x: x, y: y)
//        }

        var i = description.zeroIdx
        var j = 0
        while i <= chart.indexRange.endIdx {
            let timestamp = chart.timestamps[i]
            let str = formatter.axisDateText(timestamp: timestamp)
            labels[j].text = str
            labels[j].sizeToFit()
            labels[j].center = CGPoint(x: calc.x(in: bounds, timestamp: timestamp), y: y)
//            let size = str.boundingRect(
//                    with: rect.size,
//                    options: options,
//                    attributes: attributes,
//                    context: nil)
//
//            let frame = CGRect(
//                    x: (calculator.x(in: rect, timestamp: timestamp) - size.width / 2).screenScaledFloor,
//                    y: (rect.origin.y + (rect.size.height - size.height) / 2).screenScaledFloor,
//                    width: ceil(size.width),
//                    height: ceil(size.size.height))
//
//            str.draw(with: frame, options: options, attributes: attributes, context: nil)
            i += description.step
            j += 1
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
            let label = self.createLabel()
            label.alpha = 0
            self.addSubview(label)
            return label
        }

        if labels.count == 0 {
            let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)



            let x1 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx])
            let x2 = calc.x(in: bounds, timestamp: chart.timestamps[description.zeroIdx + description.step])
            let spacing = (x2 - x1)

            var label = getLabel()
            label.alpha = 0
            closerLabels.append(label)

            var i = 0
            while true {
                let x = x1 + CGFloat(i) * spacing
                if x > bounds.maxX {
                    break
                }
                label = getLabel()
                labels.append(label)
                closerLabels.append(label)
                if i % 2 == 0 {
                    widerLabels.append(label)
                }
                label = getLabel()
                label.alpha = 0
                closerLabels.append(label)
                i += 1
            }

            label = getLabel()
            label.alpha = 0
            closerLabels.append(label)
        }

        guard let descr = prevDescr else {
            return
        }

        if descr.step < description.step {
            // TODO: perfomans! n^2
            let toRemove = closerLabels.filter {
                !widerLabels.contains($0)
            }
            labels = widerLabels
            closerLabels.removeAll()
            widerLabels.removeAll()

            var newLabel = getLabel()
            newLabel.alpha = 0
            closerLabels.append(newLabel)

            for (idx, label) in labels.enumerated() {
                if idx % 2 == 0 {
                    widerLabels.append(label)
                }
                closerLabels.append(label)
                newLabel = getLabel()
                newLabel.alpha = 0
                closerLabels.append(label)
            }

            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                toRemove.forEach {
                    $0.alpha = 0
                }
            }, completion: { b in
                toRemove.forEach {
                    $0.removeFromSuperview()
                }
            })
        } else if descr.step > description.step {
            labels = closerLabels
            closerLabels.removeAll()
            widerLabels.removeAll()

            var newLabel = getLabel()
            newLabel.alpha = 0
            closerLabels.append(newLabel)

            for (idx, label) in labels.enumerated() {
                if idx % 2 == 0 {
                    widerLabels.append(label)
                }
                closerLabels.append(label)
                newLabel = getLabel()
                newLabel.alpha = 0
                closerLabels.append(label)
            }

            UIView.animate(withDuration: 0.3, animations: { [labels] () -> Void in
                labels.forEach {
                    $0.alpha = 1
                }
            })
        }
    }

    private func updateDescription() {
        guard let chart = chart, !bounds.isEmpty else {
            return
        }
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

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.text = formatter.sizingString
        label.textColor = textColor
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        return label
    }
}
