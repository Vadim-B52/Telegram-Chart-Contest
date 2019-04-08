//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class CompoundChartView: UIView, ChartViewProtocol {

    private let chartView = ChartView()
    private let crosshairView = CrosshairView()
    private let timeAxisView = TimeAxisView()
    private var valuePanelConfig: ValueAxisPanel.Config!

    public weak var timeAxisDelegate: ChartViewTimeAxisDelegate?
    fileprivate var timeAxisDescription: TimeAxisDescription? {
        get {
            return timeAxisDelegate?.timeAxisDescription(chartView: self)
        }
        set {
            timeAxisDelegate?.chartView(self, didChangeTimeAxisDescription: newValue)
        }
    }

    public weak var colorSource: ChartViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public weak var animationProgressDataSource: ChartViewAnimationProgressDataSource?

    private var chart: DrawingChart?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true

        chartView.lineWidth = 2
        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)

        timeAxisView.translatesAutoresizingMaskIntoConstraints = false
        timeAxisView.delegate = self
        addSubview(timeAxisView)

        crosshairView.colorSource = self
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(crosshairView)
        
        reloadColors()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            if newValue != super.bounds {
                timeAxisDescription = nil
            }
            super.bounds = newValue
        }
    }
    
    public override func layoutSubviews() {
        let (timeFrame, chartFrame) = bounds.divided(atDistance: 24, from: .maxYEdge)
        timeAxisView.frame = timeFrame
        crosshairView.frame = chartFrame
        chartView.frame = chartFrame
    }

    public func displayChart(_ chart: DrawingChart?, animated: Bool) {
        crosshairView.chart = chart
        timeAxisView.displayChart(chart: chart, timeAxisDescription: self.timeAxisDescription)
        setNeedsDisplay()
        chartView.displayChart(chart, animated: animated)
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let bounds = integralBounds
        let (_, chartRect) = bounds.divided(atDistance: 24, from: .maxYEdge)

        var valuePanelConfig = self.valuePanelConfig!
        if let animationProgress = animationProgressDataSource?.animationProgressAlpha(chartView: self) {
            let color = valuePanelConfig.axisColor.withAlphaComponent(animationProgress)
            valuePanelConfig = ValueAxisPanel.Config(
                    axisColor: color,
                    zeroAxisColor: color,
                    textColor: valuePanelConfig.textColor.withAlphaComponent(animationProgress))
        }
        let valuePanel = ValueAxisPanel(chart: chart, config: valuePanelConfig)
        valuePanel.drawInContext(ctx, rect: chartRect)
    }

    public func reloadColors() {
        crosshairView.reloadColors()
        reloadValuePanelConfig()
        setNeedsDisplay()
    }

    private func reloadValuePanelConfig() {
        guard let colorSource = colorSource else {
            valuePanelConfig = ValueAxisPanel.Config(
                    axisColor: .gray,
                    zeroAxisColor: .gray,
                    textColor: .gray)
            return
        }
        timeAxisView.textColor = colorSource.chartAxisLabelColor(chartView: self)
        valuePanelConfig = ValueAxisPanel.Config(
                axisColor: colorSource.valueAxisColor(chartView: self),
                zeroAxisColor: colorSource.zeroValueAxisColor(chartView: self),
                textColor: colorSource.chartAxisLabelColor(chartView: self))
    }
}

extension CompoundChartView: CrosshairViewColorSource {
    public func pointFillColor(crosshairView: CrosshairView) -> UIColor {
        return colorSource?.backgroundColor(chartView: self) ?? UIColor.white
    }

    public func lineColor(crosshairView: CrosshairView) -> UIColor {
        return colorSource?.zeroValueAxisColor(chartView: self) ?? UIColor.gray
    }

    public func popupBackgroundColor(crosshairView: CrosshairView) -> UIColor {
        return colorSource?.popupBackgroundColor(chartView: self) ?? UIColor.gray
    }

    public func popupTextColor(crosshairView: CrosshairView) -> UIColor {
        return colorSource?.popupLabelColor(chartView: self) ?? UIColor.white
    }
}

extension CompoundChartView: TimeAxisViewDelegate {
    public func timeAxisView(_ view: TimeAxisView, didUpdateTimeAxisDescription descr: TimeAxisDescription) {
        if descr != timeAxisDescription {
            timeAxisDescription = descr
        }
    }
}

public protocol ChartViewTimeAxisDelegate: AnyObject {
    func chartView(_ chartView: CompoundChartView, didChangeTimeAxisDescription description: TimeAxisDescription?)
    func timeAxisDescription(chartView: CompoundChartView) -> TimeAxisDescription?
}

public protocol ChartViewColorSource: AnyObject {
    func valueAxisColor(chartView: CompoundChartView) -> UIColor
    func zeroValueAxisColor(chartView: CompoundChartView) -> UIColor
    func chartAxisLabelColor(chartView: CompoundChartView) -> UIColor
    func popupBackgroundColor(chartView: CompoundChartView) -> UIColor
    func popupLabelColor(chartView: CompoundChartView) -> UIColor
    func backgroundColor(chartView: CompoundChartView) -> UIColor
}

public protocol ChartViewAnimationProgressDataSource: AnyObject {
    func animationProgressAlpha(chartView: ChartViewProtocol) -> CGFloat?
}
