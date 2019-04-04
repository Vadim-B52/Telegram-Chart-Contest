//
// Created by Vadim on 2019-03-18.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class CrosshairView: UIView {

    private let longPress = UILongPressGestureRecognizer()
    private var popup: PopupView?

    private var crosshairTimeIdx: Int? {
        didSet {
            guard crosshairTimeIdx != oldValue else {
                return
            }
            updateWithCrosshairIdx()
        }
    }

    private var crosshairConfig = CrosshairPanel.Config(pointFillColor: .clear, lineColor: .gray)

    public weak var colorSource: CrosshairViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public var chart: DrawingChart? = nil {
        didSet {
            if chart == nil {
                crosshairTimeIdx = nil
                popup?.removeFromSuperview()
                popup = nil
            }
            setNeedsDisplay()
            setNeedsLayout()
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

        let panel = CrosshairPanel(chart: chart, timestampIndex: idx, config: crosshairConfig)
        panel.drawInContext(ctx, rect: bounds)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if let popup = popup, let idx = crosshairTimeIdx, let chart = chart  {
            var frame = CGRect.zero
            frame.origin.y = 6
            frame.size = popup.systemLayoutSizeFitting(.zero)
            let timestamp: Int64 = chart.timestamps[idx]
            let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
            let x = calc.x(in: bounds, timestamp: timestamp)
            frame.origin.x = x - frame.width / 2

            for plot in chart.plots {
                let yCalc = DrawingChart.YCalculator(valueRange: chart.valueRange)
                let y = yCalc.y(in: bounds, value: plot.values[idx])
                if frame.contains(CGPoint(x: x, y: y)) {
                    var frame1 = frame
                    frame1.origin.x = x - frame.width - 10
                    if bounds.contains(frame1) {
                        frame = frame1
                        break
                    }
                    frame.origin.x = x + 10
                    break
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

        crosshairConfig = CrosshairPanel.Config(
                pointFillColor: colorSource.pointFillColor(crosshairView: self),
                lineColor: colorSource.lineColor(crosshairView: self))

        popup?.backgroundColor = colorSource.popupBackgroundColor(crosshairView: self)
        popup?.timeLabel.textColor = colorSource.popupTextColor(crosshairView: self)

        setNeedsDisplay()
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
        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let ts = calc.timestampAt(x: point.x, rect: bounds)
        crosshairTimeIdx = chart.closestIdxTo(timestamp: ts)
    }

    private func updateWithCrosshairIdx() {
        guard let chart = chart else {
// TODO: fatal error
            return
        }
        if let idx = crosshairTimeIdx {
            let popup = ensurePopupView()
            let timestamp: Int64 = chart.timestamps[idx]
            let formatter = ChartTextFormatter.shared
            popup.timeLabel.attributedText = formatter.popupDateText(timestamp: timestamp)
            popup.valueLabel.attributedText = formatter.popupValueText(index: idx, plots: chart.plots)
            setNeedsLayout()
//            TODO: animated if needed
//            let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveLinear]
//            UIView.animate(withDuration: 0.05, delay: 0, options: options, animations: {
//                self.layoutIfNeeded()
//            }, completion: nil)
        } else {
            popup?.removeFromSuperview()
            popup = nil
        }
        setNeedsDisplay()
    }

    private func ensurePopupView() -> PopupView {
        if let view = popup {
            return view
        }
        let view = PopupView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        popup = view
        if let colorSource = colorSource {
            view.backgroundColor = colorSource.popupBackgroundColor(crosshairView: self)
            view.timeLabel.textColor = colorSource.popupTextColor(crosshairView: self)
        }
        return view
    }
}

fileprivate extension CrosshairView {
    private class PopupView: UIView {

        let timeLabel = UILabel()
        let valueLabel = UILabel()

        public override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
            layer.cornerRadius = 4

            timeLabel.numberOfLines = 0
            timeLabel.font = Fonts.current.bold11()
            valueLabel.numberOfLines = 0
            valueLabel.textAlignment = .right
            valueLabel.font = Fonts.current.semibold12()

            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(timeLabel)
            addSubview(valueLabel)

            let views = ["time": timeLabel, "value": valueLabel]
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-9-[time]-20@750-[value]-9-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-5-[time]->=5-|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-5-[value]-5@249-|",
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
