//
// Created by Vadim on 2019-04-08.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class YAxisView: UIView, ChartViewProtocol {

    private var views: [OneYAxis]

    private var chart: DrawingChart?
    var valuePanelConfig: ValueAxisPanel.Config! {
        didSet {
            if valuePanelConfig == nil {
                valuePanelConfig = ValueAxisPanel.Config(
                        axisColor: .gray,
                        zeroAxisColor: .gray,
                        textColor: .gray)
            }
            updateSkin()
        }
    }

    override init(frame: CGRect) {
        var views = [OneYAxis]()
        for _ in 0..<5 {
            views.append(OneYAxis())
        }
        self.views = views
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        backgroundColor = .clear
        valuePanelConfig = nil

        views.forEach { v in
            addSubview(v)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let chart = chart else {
            return
        }

        let plot = chart.visiblePlots.first!
        let calculator = DrawingChart.YCalculator(valueRange: chart.valueRange(plot: plot))
        let yAxisValues = chart.axisValues(plot: plot)

        for (idx, view) in views.enumerated() {
            let maxY = calculator.y(in: bounds, value: yAxisValues.zero + Int64(idx) * yAxisValues.step)
            let height = view.sizeThatFits(.zero).height
            view.frame = CGRect(x: bounds.minX, y: maxY - height, width: bounds.width, height: height)
            view.isHidden = maxY <= bounds.minY
        }
    }

    func displayChart(_ chart:DrawingChart?, animation: ChartViewAnimation) {
        self.chart = chart
        updateSkin()
        setNeedsLayout()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let valuePanelConfig = self.valuePanelConfig!
        let (zeroLine, _) = bounds.divided(atDistance: ScreenHelper.lightLineWidth, from: .maxYEdge)
        valuePanelConfig.zeroAxisColor.setFill()
        ctx.fill(zeroLine)
    }

    private func updateSkin() {
        guard let chart = chart else {
            return
        }
        for (idx, view) in views.enumerated() {
            view.lineColor = valuePanelConfig.axisColor
            var leftValue: NSAttributedString!
            var rightValue: NSMutableAttributedString!
            for plot in chart.visiblePlots {
                let firstPlotYAxisValues = chart.axisValues(plot: chart.allPlots.first!)
                let firstPlotVal = firstPlotYAxisValues.zero + Int64(idx) * firstPlotYAxisValues.step
                let yAxisValues = chart.axisValues(plot: plot)
                let val = yAxisValues.zero + Int64(idx) * yAxisValues.step
                if firstPlotVal == val {
                    leftValue = NSAttributedString(
                            string: "\(val)",
                            attributes: [NSAttributedString.Key.foregroundColor: valuePanelConfig.textColor])
                } else {
                    if rightValue == nil {
                        rightValue = NSMutableAttributedString()
                    }
                    rightValue.append(NSAttributedString(
                            string: ", ",
                            attributes: [NSAttributedString.Key.foregroundColor: valuePanelConfig.textColor]))
                    rightValue.append(NSAttributedString(
                            string: "\(val)",
                            attributes: [NSAttributedString.Key.foregroundColor: plot.color]))
                }
            }
            if rightValue != nil {
                rightValue.replaceCharacters(in: NSRange(location: 0, length: 2), with: "")
            }
            view.setLeftValue(leftValue)
            view.setRightValue(rightValue)
        }
    }
}

class OneYAxis: UIView {

    private let leftLabel = UILabel()
    private let rightLabel = UILabel()
    private let font = Fonts.current.light11()

    var lineColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        contentMode = .redraw
        isOpaque = true
        backgroundColor = .clear
        leftLabel.textAlignment = .left
        rightLabel.textAlignment = .right

        [leftLabel, rightLabel].forEach { label in
            label.font = font
            label.frame = bounds
            label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            addSubview(label)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let (line, _) = bounds.divided(atDistance: ScreenHelper.lightLineWidth, from: .maxYEdge)
        lineColor?.setFill()
        ctx.fill(line)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: ceil(font.lineHeight))
    }

    func setLeftValue(_ value: NSAttributedString?) {
        leftLabel.attributedText = value
    }

    func setRightValue(_ value: NSAttributedString?) {
        rightLabel.attributedText = value
    }
}
