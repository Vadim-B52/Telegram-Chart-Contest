//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class CompoundChartView: UIView, ChartViewProtocol {

    private let chartView = ChartView()
    private let crosshairView = CrosshairView()
    private let timeAxisView = TimeAxisView()
    private let yAxisView = YAxisView()
    private let headerView = UILabel()

    public weak var timeAxisDelegate: ChartViewTimeAxisDelegate?
    fileprivate var timeAxisDescription: TimeAxisDescription? {
        get {
            return timeAxisDelegate?.timeAxisDescription(chartView: self)
        }
        set {
            timeAxisDelegate?.chartView(self, didChangeTimeAxisDescription: newValue)
        }
    }

    public weak var colorSource: CompoundChartViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public weak var animationProgressDataSource: ChartViewAnimationProgressDataSource?

    private var chart: DrawingChart?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(yAxisView)

        chartView.colorSource = self
        chartView.lineWidth = 2
        addSubview(chartView)

        timeAxisView.delegate = self
        addSubview(timeAxisView)

        crosshairView.colorSource = self
        addSubview(crosshairView)

        headerView.font = Fonts.current.bold13()
        headerView.textAlignment = .center
        addSubview(headerView)
        
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
        let headerFrame: CGRect
        var (timeFrame, chartFrame) = bounds.divided(atDistance: 24, from: .maxYEdge)
        (headerFrame, chartFrame) = chartFrame.divided(atDistance: 40, from: .minYEdge)
        headerView.frame = headerFrame
        timeAxisView.frame = timeFrame
        crosshairView.frame = chartFrame
        chartView.frame = chartFrame
        yAxisView.frame = chartFrame
    }

    public func displayChart(_ chart: DrawingChart?, animation: ChartViewAnimation) {
        if chart?.allPlots.first(where: { $0.type != .line }) == nil {
            [yAxisView, chartView, timeAxisView, crosshairView].forEach { bringSubviewToFront($0) }
        } else {
            [chartView, yAxisView, timeAxisView, crosshairView].forEach { bringSubviewToFront($0) }
        }
        crosshairView.chart = chart
        timeAxisView.displayChart(chart: chart, timeAxisDescription: self.timeAxisDescription)
        chartView.displayChart(chart, animation: animation)
        yAxisView.displayChart(chart, animation: animation)

        if let chart = chart {
            let ts1 = chart.timestamps[chart.timeIndexRange.startIdx]
            let ts2 = chart.timestamps[chart.timeIndexRange.endIdx]
            let f = ChartTextFormatter.shared
            headerView.text = "\(f.headerText(timestamp: ts1)) - \(f.headerText(timestamp: ts2))"
        }
    }

    public func reloadColors() {
        headerView.textColor = colorSource?.headerTextColor(chartView: self)
        crosshairView.reloadColors()
        reloadValuePanelConfig()
        setNeedsDisplay()
    }

    private func reloadValuePanelConfig() {
        guard let colorSource = colorSource else {
            yAxisView.valuePanelConfig = nil
            return
        }
        timeAxisView.textColor = colorSource.chartAxisLabelColor(chartView: self)
        yAxisView.valuePanelConfig = ValueAxisPanel.Config(
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

extension CompoundChartView: ChartViewColorSource {
    public func colorToUseForAdjusting(chartView: ChartView) -> UIColor? {
        return colorSource?.colorToUseForAdjusting(chartView: self)
    }
}

public protocol ChartViewTimeAxisDelegate: AnyObject {
    func chartView(_ chartView: CompoundChartView, didChangeTimeAxisDescription description: TimeAxisDescription?)
    func timeAxisDescription(chartView: CompoundChartView) -> TimeAxisDescription?
}

public protocol CompoundChartViewColorSource: AnyObject {
    func valueAxisColor(chartView: CompoundChartView) -> UIColor
    func zeroValueAxisColor(chartView: CompoundChartView) -> UIColor
    func chartAxisLabelColor(chartView: CompoundChartView) -> UIColor
    func popupBackgroundColor(chartView: CompoundChartView) -> UIColor
    func popupLabelColor(chartView: CompoundChartView) -> UIColor
    func backgroundColor(chartView: CompoundChartView) -> UIColor
    func colorToUseForAdjusting(chartView: CompoundChartView) -> UIColor
    func headerTextColor(chartView: CompoundChartView) -> UIColor
}

public protocol ChartViewAnimationProgressDataSource: AnyObject {
    func animationProgressAlpha(chartView: ChartViewProtocol) -> CGFloat?
}
