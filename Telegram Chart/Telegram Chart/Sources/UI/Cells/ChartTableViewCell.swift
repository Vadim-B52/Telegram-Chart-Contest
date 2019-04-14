//
//  ChartTableViewCell.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartTableViewCellDelegate: AnyObject {
    func chartTableViewCell(_ cell: ChartTableViewCell, didChangeSelectedTimeRange timeRange: TimeRange)
}

public protocol ChartTableViewColorSource: AnyObject {
    func errorTextColor(chartTableViewCell cell: ChartTableViewCell) -> UIColor
    func errorBackgroundColor(chartTableViewCell cell: ChartTableViewCell) -> UIColor
}

public class ChartTableViewCell: UITableViewCell {

    private let chartView = CompoundChartView()
    private let miniChartView = ChartView()
    private let timeSelector = TimeFrameSelectorView()
    private var errorView: UILabel?

    private var chart: Chart?
    private var state: ChartState?
    fileprivate var timeAxisDescription: TimeAxisDescription?

    public weak var delegate: ChartTableViewCellDelegate?
    public weak var colorSource: ChartTableViewColorSource?
    public weak var chartViewColorSource: CompoundChartViewColorSource? {
        didSet {
            chartView.colorSource = chartViewColorSource
        }
    }
    public weak var timeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        didSet {
            timeSelector.colorSource = timeSelectorViewColorSource
        }
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        chartView.timeAxisDelegate = self
        chartView.translatesAutoresizingMaskIntoConstraints = false
        miniChartView.translatesAutoresizingMaskIntoConstraints = false
        miniChartView.colorSource = chartView // FIXME: hack

        let miniChartViewWrapper = UIView()
        miniChartViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        miniChartViewWrapper.addSubview(miniChartView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .top,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .top,
                    multiplier: 1, constant: -11),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .bottom,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .bottom,
                    multiplier: 1, constant: 9),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .leading,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .leading,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .trailing,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .trailing,
                    multiplier: 1, constant: 0),
        ])

        timeSelector.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
        contentView.addSubview(miniChartViewWrapper)
        contentView.addSubview(timeSelector)

        let views = ["chartView": chartView, "miniChartView": miniChartViewWrapper]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[chartView][miniChartView(==60)]|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-15-[chartView]-15-|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-15-[miniChartView]-15-|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate([
            NSLayoutConstraint(
                item: timeSelector, attribute: .centerX,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .centerX,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .centerY,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .centerY,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .height,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .height,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .width,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .width,
                multiplier: 1, constant: 30),
        ])

        timeSelector.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        chartView.displayChart(nil, animation: .none)
        miniChartView.displayChart(nil, animation: .none)
        timeSelector.update(timeRange: nil, selectedTimeRange: nil)
    }

    public func display(chart: Chart, state: ChartState, animation: ChartViewAnimation) {
        self.chart = chart
        self.state = state
        timeSelector.update(timeRange: chart.timeRange, selectedTimeRange: state.selectedTimeRange)
        if state.enabledPlotId.count == 0 {
            let prevErrorView = errorView
            prevErrorView?.removeFromSuperview()
            let errorView = UILabel()
            self.errorView = errorView
            contentView.addSubview(errorView)
            errorView.frame = contentView.bounds
            errorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            errorView.textAlignment = .center
            errorView.adjustsFontSizeToFitWidth = true
            errorView.minimumScaleFactor = 0.5
            errorView.text = NSLocalizedString("  Please select something to display  ", comment: "")
            errorView.backgroundColor = colorSource?.errorBackgroundColor(chartTableViewCell: self)
            errorView.textColor = colorSource?.errorTextColor(chartTableViewCell: self)
            if animation != .none && prevErrorView == nil {
                errorView.alpha = 0
                UIView.animate(withDuration: 0.3) { errorView.alpha = 1 }
            }
        } else if let errorView = errorView {
            self.errorView = nil
            UIView.animate(withDuration: animation != .none ? 0.3 : 0, animations: { errorView.alpha = 0 }) { b in
                errorView.removeFromSuperview()
            }
            chartView.displayChart(chartViewDrawingChart(), animation: .none)
            miniChartView.displayChart(miniChartViewDrawingChart(), animation: .none)
        } else {
            chartView.displayChart(chartViewDrawingChart(), animation: animation)
            miniChartView.displayChart(miniChartViewDrawingChart(), animation: animation)
        }
    }
    
    @objc
    private func handleValueChanged() {
        guard let selectedTimeRange = timeSelector.selectedTimeRange else {
            return
        }
        state = state?.byChanging(selectedTimeRange: selectedTimeRange)
        chartView.displayChart(chartViewDrawingChart(), animation: .none)
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: selectedTimeRange)
    }

    private func chartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let vrc = SelectedValueRangeCalculation()
        let yAxis: YAxisCalculation
        switch chart.chartType {
        case .simple:
            yAxis = ValueRangePrettyYAxis()
        case .stacked:
            yAxis = ValueRangePrettyYAxis()
        case .percentageStacked:
            yAxis = ValueRangeHasStaticYAxis.percentage
        case .yScaled:
            yAxis = ValueRangeExactYAxis()
        }
        
        return DrawingChart(
                chart: chart,
                enabledPlotId: state.enabledPlotId,
                timestamps: chart.timestamps,
                timeRange: state.selectedTimeRange,
                valueRangeCalculation: valueRangeCalculation(baseCalculation: vrc, chart: chart),
                yAxisCalculation: yAxis)
    }

    private func miniChartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let vrc = FullValueRangeCalculation()
        return DrawingChart(
                chart: chart,
                enabledPlotId: state.enabledPlotId,
                timestamps: chart.timestamps,
                valueRangeCalculation: valueRangeCalculation(baseCalculation: vrc, chart: chart),
                yAxisCalculation: ValueRangeNoYAxisStrategy())
    }

    private func valueRangeCalculation(baseCalculation: ValueRangeCalculation, chart: Chart) -> ValueRangeCalculation {
        switch chart.chartType {
        case .simple:
            return valueRangeCalculation(forSimpleChart: chart, baseCalculation: baseCalculation)
        case .yScaled:
            return YScaledValueRangeCalculation(internalCalculation: baseCalculation)
        case .stacked:
            return StackedValueRangeCalculation()
        case .percentageStacked:
            return StaticValueRangeCalculation.percentage
        }
    }

    private func valueRangeCalculation(
            forSimpleChart chart: Chart,
            baseCalculation: ValueRangeCalculation) -> ValueRangeCalculation {

        return chart.plots.contains { $0.type == .bar } ?
                VolumeStyleValueRangeCalculation(internalCalculation: baseCalculation) :
                baseCalculation;
    }
}

extension ChartTableViewCell: ChartViewTimeAxisDelegate {

    public func chartView(_ chartView: CompoundChartView, didChangeTimeAxisDescription description: TimeAxisDescription?) {
        self.timeAxisDescription = description
    }

    public func timeAxisDescription(chartView: CompoundChartView) -> TimeAxisDescription? {
        return timeAxisDescription
    }
}
