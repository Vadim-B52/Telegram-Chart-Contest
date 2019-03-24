//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView, ChartViewProtocol {

    private let crosshairView = CrosshairView()
    private let timeAxisView = TimeAxisView()
    private var valuePanelConfig: ValueAxisPanel.Config!

    public weak var timeAxisDelegate: ChartViewTimeAxisDelegate?
    fileprivate var timeAxisDescription: TimeAxisDescription? {
        get {
            return timeAxisDelegate?.timeAxisDescription(self)
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

    public var chart: DrawingChart? {
        didSet {
            crosshairView.chart = chart
            timeAxisView.displayChart(chart: chart, timeAxisDescription: self.timeAxisDescription)
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true

        timeAxisView.translatesAutoresizingMaskIntoConstraints = false
        timeAxisView.delegate = self
        addSubview(timeAxisView)

        crosshairView.colorSource = self
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(crosshairView)

        NSLayoutConstraint.activate([
            crosshairView.topAnchor.constraint(equalTo: topAnchor),
            crosshairView.leadingAnchor.constraint(equalTo: leadingAnchor),
            crosshairView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            crosshairView.trailingAnchor.constraint(equalTo: trailingAnchor),

            timeAxisView.bottomAnchor.constraint(equalTo: bottomAnchor),
            timeAxisView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeAxisView.trailingAnchor.constraint(equalTo: trailingAnchor),
            timeAxisView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
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

        for plot in chart.plots {
            let panel = ChartPanel(
                    timestamps: chart.timestamps,
                    indexRange: chart.indexRange,
                    timeRange: chart.selectedTimeRange,
                    valueRange: chart.valueRange,
                    plot: plot,
                    lineWidth: 2)
            
            panel.drawInContext(ctx, rect: chartRect)
        }
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

extension ChartView: CrosshairViewColorSource {
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

extension ChartView: TimeAxisViewDelegate {
    public func timeAxisView(_ view: TimeAxisView, didUpdateTimeAxisDescription descr: TimeAxisDescription) {
        if descr != timeAxisDescription {
            timeAxisDescription = descr
        }
    }
}

public protocol ChartViewTimeAxisDelegate: AnyObject {
    func chartView(_ chartView: ChartView, didChangeTimeAxisDescription description: TimeAxisDescription?)
    func timeAxisDescription(_ chartView: ChartView) -> TimeAxisDescription?
}

public protocol ChartViewColorSource: AnyObject {
    func valueAxisColor(chartView: ChartView) -> UIColor
    func zeroValueAxisColor(chartView: ChartView) -> UIColor
    func chartAxisLabelColor(chartView: ChartView) -> UIColor
    func popupBackgroundColor(chartView: ChartView) -> UIColor
    func popupLabelColor(chartView: ChartView) -> UIColor
    func backgroundColor(chartView: ChartView) -> UIColor
}

public protocol ChartViewAnimationProgressDataSource: AnyObject {
    func animationProgressAlpha(chartView: ChartViewProtocol) -> CGFloat?
}
