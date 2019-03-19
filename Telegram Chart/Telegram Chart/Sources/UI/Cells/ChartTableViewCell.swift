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

public class ChartTableViewCell: UITableViewCell {

    private let chartView = ChartView()
    private let miniChartView = MiniChartView()
    private var chartAnimator: ChartViewAnimator?
    private var miniChartAnimator: ChartViewAnimator?
    private var chart: Chart?
    private var state: ChartState?

    public weak var delegate: ChartTableViewCellDelegate?

    public override var backgroundColor: UIColor? {
        get {
            return super.backgroundColor
        }
        set {
            super.backgroundColor = newValue
            chartView.backgroundColor = newValue
            miniChartView.backgroundColor = newValue
        }
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        chartView.backgroundColor = .white
        miniChartView.backgroundColor = .white

        chartView.translatesAutoresizingMaskIntoConstraints = false
        miniChartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
        contentView.addSubview(miniChartView)

        let views = ["chartView": chartView, "miniChartView": miniChartView]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[chartView][miniChartView(==60)]|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[chartView]-15-|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[miniChartView]-15-|",
                options: [], metrics: nil, views: views))

        miniChartView.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func display(chart: Chart, state: ChartState) {
        self.chart = chart
        self.state = state

        updateChartView()
        updateMiniChartView()
    }

    public func hidePlot(plotId: String) {
//        state = state.byDisablingPlotWith(identifier: plotId)
//        dispatchAnimation(toShow: false, identifier: plotId)
    }

    public func showPlot(plotId: String) {
//        state = state.byEnablingPlotWith(identifier: plotId)
//        dispatchAnimation(toShow: true, identifier: plotId)
    }

//    private func dispatchAnimation(toShow: Bool, identifier: String) {
//        let oldDrawingChart = drawingChart!
//        let newDrawingChart = DrawingChart(
//                timestamps: drawingChart.timestamps,
//                timeRange: drawingChart.timeRange,
//                selectedTimeRange: drawingChart.selectedTimeRange,
//                plots: chart.plots.filter {
//                    state.enabledPlotId.contains($0.identifier)
//                })
//
//        if toShow {
//            drawingChart = newDrawingChart
//        }
//
//        let startValue = ChartViewAnimator.Value(valueRange: oldDrawingChart.valueRange, alpha: toShow ? 0 : 1)
//        let endValue = ChartViewAnimator.Value(valueRange: newDrawingChart.valueRange, alpha: toShow ? 1 : 0)
//        let animator = ChartViewAnimator(identifier: identifier, animationDuration: 0.3, startValue: startValue, endValue: endValue)
//        animator.callback = { (finished, value) in
//            self.reloadData()
//            if finished {
//                self.animator = nil
//                self.drawingChart = newDrawingChart
//            }
//        }
//        self.animator = animator
//        animator.startAnimation()
//    }

    @objc
    private func handleValueChanged() {
        guard let selectedTimeRange = miniChartView.selectedTimeRange else {
            return
        }
        state = state?.byChanging(selectedTimeRange: selectedTimeRange)
        updateChartView()
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: selectedTimeRange)
    }

    private func updateChartView() {
        guard let chart = chart, let state = state else {
            return
        }
        let plots = chart.plots.filter {
            state.enabledPlotId.contains($0.identifier)
        }
        chartView.chart = DrawingChart(
                plots: plots,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                selectedTimeRange: state.selectedTimeRange,
                valueRangeCalculation: SelectedValueRangeCalculation())
    }

    private func updateMiniChartView() {
        guard let chart = chart, let state = state else {
            return
        }
        let plots = chart.plots.filter {
            state.enabledPlotId.contains($0.identifier)
        }
        miniChartView.chart = DrawingChart(
                plots: plots,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                selectedTimeRange: state.selectedTimeRange,
                valueRangeCalculation: FullValueRangeCalculation())
    }
}

public extension ChartTableViewCell {
    public weak var miniChartTimeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        get {
            return miniChartView.miniChartTimeSelectorViewColorSource
        }
        set {
            miniChartView.miniChartTimeSelectorViewColorSource = newValue
        }
    }
}

public extension ChartTableViewCell {
    public weak var chartViewColorSource: ChartViewColorSource? {
        get {
            return chartView.colorSource
        }
        set {
            chartView.colorSource = newValue
        }
    }
}
