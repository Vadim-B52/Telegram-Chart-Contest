//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView, ChartViewProtocol {

    private let crosshairView = CrosshairView()
    private var timePanelConfig: TimeAxisPanel.Config!
    private var valuePanelConfig: ValueAxisPanel.Config!

    public weak var timeAxisDelegate: ChartViewTimeAxisDelegate?
    private var timeAxisDescription: TimeAxisDescription? {
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

    public var chart: DrawingChart? {
        didSet {
            if oldValue?.timeRange != chart?.timeRange {
                timeAxisDescription = nil
            }
            crosshairView.chart = chart
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true

        crosshairView.colorSource = self
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(crosshairView)
        NSLayoutConstraint.activate([
            crosshairView.topAnchor.constraint(equalTo: topAnchor),
            crosshairView.leadingAnchor.constraint(equalTo: leadingAnchor),
            crosshairView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            crosshairView.trailingAnchor.constraint(equalTo: trailingAnchor),
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
        
        let (timeRect, chartRect) = bounds.divided(atDistance: 24, from: .maxYEdge)
        let oldTimeAxisDescription = self.timeAxisDescription
        let timePanel = TimeAxisPanel(chart: chart, description: oldTimeAxisDescription, config: timePanelConfig)
        let timeAxisDescription = timePanel.drawInContext(ctx, rect: timeRect)
        if timeAxisDescription != oldTimeAxisDescription {
            self.timeAxisDescription = timeAxisDescription
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
        reloadTimePanelConfig()
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
        valuePanelConfig = ValueAxisPanel.Config(
                axisColor: colorSource.zeroValueAxisColor(chartView: self),
                zeroAxisColor: colorSource.zeroValueAxisColor(chartView: self),
                textColor: colorSource.chartAxisLabelColor(chartView: self))
    }

    private func reloadTimePanelConfig() {
        guard let colorSource = colorSource else {
            timePanelConfig = TimeAxisPanel.Config(textColor: .gray)
            return
        }
        timePanelConfig = TimeAxisPanel.Config(textColor: colorSource.chartAxisLabelColor(chartView: self))

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
