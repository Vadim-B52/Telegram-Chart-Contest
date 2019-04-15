//
// Created by Vadim on 2019-03-18.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class CrosshairView: UIView {

    private let longPress = UILongPressGestureRecognizer()
    private let tap = UITapGestureRecognizer()
    private var popup: PopupView?
    private var crosshairTimeIdx: Int?

    private var crosshairConfig = CrosshairPanelConfig(pointFillColor: .clear, lineColor: .gray)

    public weak var delegate: CrosshairViewDelegate? {
        didSet {
            crosshairTimeIdx = delegate?.getStoredIdx(crosshairView: self)
            updateWithCrosshairIdx(animated: false)
        }
    }

    public weak var colorSource: CrosshairViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()
            setNeedsLayout()
            if chart == nil {
                crosshairTimeIdx = nil
            }
            updateWithCrosshairIdx(animated: false)
        }
    }

    public var chartInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentMode = .redraw
        isOpaque = true
        longPress.minimumPressDuration = 0.175
        longPress.addTarget(self, action: #selector(handleLongPress))
        addGestureRecognizer(longPress)
        tap.addTarget(self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
              let idx = crosshairTimeIdx,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        let panel = makePanel(chart: chart, idx: idx)
        panel.drawInContext(ctx, rect: bounds.inset(by: chartInsets))
    }

    private func makePanel(chart: DrawingChart, idx: Int) -> CrosshairPanel {
        let panel: CrosshairPanel
        switch (chart.chart.chartType) {
        case .simple:
            panel = LineCrosshairPanel(chart: chart, timestampIndex: idx, config: crosshairConfig)
        case .yScaled:
            panel = LineCrosshairPanel(chart: chart, timestampIndex: idx, config: crosshairConfig)
        case .stacked:
            panel = StackedBarCrosshairPanel(chart: chart, timestampIndex: idx, config: crosshairConfig)
        case .percentageStacked:
            panel = PercentageAreaCrosshairPanel(chart: chart, timestampIndex: idx, config: crosshairConfig)
        }
        return panel
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if let popup = popup, let idx = crosshairTimeIdx, let chart = chart  {
            let bounds = self.bounds.inset(by: chartInsets)
            var frame = CGRect.zero
            frame.origin.y = 6
            frame.size = popup.systemLayoutSizeFitting(.zero)
            let timestamp: Int64 = chart.timestamps[idx]
            let calc = DrawingChart.XCalculator(timeRange: chart.timeRange)
            let x = calc.x(in: bounds, timestamp: timestamp)
            frame.origin.x = x - frame.width / 2

            let panel = makePanel(chart: chart, idx: idx)

            if let moveRectToLeft = panel.getMoveRectToLeft(bounds: bounds, frame: frame, x: x) {
                if moveRectToLeft {
                    var frame1 = frame
                    frame1.origin.x = x - frame.width - 10
                    frame = frame1
                } else {
                    frame.origin.x = x + 10
                }
            }

            if frame.minX < bounds.minX {
                frame.origin.x = bounds.minX
            } else if frame.maxX > bounds.maxX {
                frame.origin.x = bounds.maxX - frame.width
            }
            popup.frame = frame
            popup.alpha = bounds.minX <= x && x <= bounds.maxX ? 1 : 0
        }
    }

    public func reloadColors() {
        guard let colorSource = colorSource else {
            return
        }

        crosshairConfig = CrosshairPanelConfig(
                pointFillColor: colorSource.pointFillColor(crosshairView: self),
                lineColor: colorSource.lineColor(crosshairView: self))

        popup?.backgroundColor = colorSource.popupBackgroundColor(crosshairView: self)
        let textColor = colorSource.popupTextColor(crosshairView: self)
        popup?.timeLabel.textColor = textColor
        popup?.descriptionLabel.textColor = textColor

        setNeedsDisplay()
    }

    @objc
    private func handleTap() {
        crosshairTimeIdx = nil
        updateWithCrosshairIdx(animated: true)
        delegate?.crosshairView(self, storeIdx: nil)
    }

    @objc
    private func handleLongPress() {
        switch longPress.state {
        case .began:
            updateCrosshair(point: longPress.location(in: self))
            break
        case .changed:
            updateCrosshair(point: longPress.location(in: self))
            break
        default:
            break
        }
    }

    private func updateCrosshair(point: CGPoint) {
        guard let chart = chart else {
            return
        }
        let calc = DrawingChart.XCalculator(timeRange: chart.timeRange)
        let ts = calc.timestampAt(x: point.x, rect: bounds.inset(by: chartInsets))
        crosshairTimeIdx = chart.closestIdxTo(timestamp: ts)
        delegate?.crosshairView(self, storeIdx: crosshairTimeIdx)
        setNeedsUpdate()
    }

    private var needsUpdate = false
    private func setNeedsUpdate() {
        guard !needsUpdate else {
            return
        }
        needsUpdate = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard self?.needsUpdate ?? false else {
                return
            }
            self?.updateWithCrosshairIdx(animated: true)
        }
    }

    private func updateWithCrosshairIdx(animated: Bool) {
        needsUpdate = false
        guard let chart = chart else {
            return
        }

        if let idx = crosshairTimeIdx {
            let popup = ensurePopupView()
            updateData(popup: popup, chart: chart, idx: idx)
            setNeedsLayout()
            if animated {
                let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveLinear]
                UIView.animate(withDuration: Animations.duration, delay: 0, options: options, animations: {
                    self.layoutIfNeeded()
                }, completion: nil)
            }
        } else {
            let popup = self.popup
            self.popup = nil
            UIView.animate(withDuration: animated ? Animations.duration : 0, animations: {
                popup?.alpha = 0
            }) { b in
                popup?.removeFromSuperview()
            }
        }
        setNeedsDisplay()
    }

    private func updateData(popup: PopupView, chart: DrawingChart, idx: Int) {
        let timestamp: Int64 = chart.timestamps[idx]
        let formatter = ChartTextFormatter.shared
        popup.timeLabel.attributedText = formatter.popupDateText(timestamp: timestamp)
        let valueText = formatter.popupValueText(index: idx, plots: chart.visiblePlots).mutableCopy() as! NSMutableAttributedString

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.foregroundColor] = colorSource?.popupTextColor(crosshairView: self)
        var str: String!
        chart.visiblePlots.forEach { plot in
            str = str ?? ""
            str += "\n\(plot.name)"
        }
        if str != nil {
            str.removeFirst()
        }

        let descr = NSMutableAttributedString(
                string: str,
                attributes: attributes)

        // TODO: extract classes
        switch chart.chart.chartType {
        case .simple:
            break
        case .yScaled:
            break
        case .percentageStacked:
            break
        case .stacked:
            descr.append(NSAttributedString(string: NSLocalizedString("\nAll", comment: ""), attributes: attributes))
            let calc = DrawingChart.StackedYCalculator(valueRange: .percentage, plots: chart.visiblePlots, plotIdx: 0)
            valueText.append(NSAttributedString(string: "\n\(calc.allValueAt(idx))", attributes: attributes))
        }

        descr.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: formatter.paragraphStyle(alignment: popup.descriptionLabel.textAlignment),
                range: NSRange(location: 0, length: descr.length))

        popup.valueLabel.attributedText = valueText
        popup.descriptionLabel.attributedText = descr
    }

    private func ensurePopupView() -> PopupView {
        if let view = popup {
            return view
        }
        let view = PopupView()
        view.alpha = 0
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        popup = view
        if let colorSource = colorSource {
            view.backgroundColor = colorSource.popupBackgroundColor(crosshairView: self)
            view.timeLabel.textColor = colorSource.popupTextColor(crosshairView: self)
        }
        layoutIfNeeded()
        return view
    }
}

fileprivate extension CrosshairView {
    private class PopupView: UIView {

        let timeLabel = UILabel()
        let descriptionLabel = UILabel()
        let valueLabel = UILabel()

        public override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
            layer.cornerRadius = 4

            timeLabel.font = Fonts.current.bold11()
            descriptionLabel.textAlignment = .left
            descriptionLabel.font = Fonts.current.regular11()
            valueLabel.textAlignment = .right
            valueLabel.font = Fonts.current.semibold12()

            let views = ["time": timeLabel, "value": valueLabel, "description": descriptionLabel]
            views.values.forEach { l in
                l.numberOfLines = 0
                l.translatesAutoresizingMaskIntoConstraints = false
                addSubview(l)
            }

            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-9-[time]-(>=9)-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "H:[time]-9@249-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-9-[description]-(>=20)-[value]-9-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-5-[time]-3-[description]->=5-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-5-[time]-3-[value]-5@249-|",
                    metrics: nil,
                    views: views))
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

public protocol CrosshairViewColorSource: AnyObject {
    func pointFillColor(crosshairView: CrosshairView) -> UIColor
    func lineColor(crosshairView: CrosshairView) -> UIColor
    func popupBackgroundColor(crosshairView: CrosshairView) -> UIColor
    func popupTextColor(crosshairView: CrosshairView) -> UIColor
}

public protocol CrosshairViewDelegate: AnyObject {
    func crosshairView(_ view: CrosshairView, storeIdx: Int?)
    func getStoredIdx(crosshairView: CrosshairView) -> Int?
}
