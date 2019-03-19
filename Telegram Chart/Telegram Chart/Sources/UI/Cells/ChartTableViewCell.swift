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
    private lazy var chartDataSource: ChartDataSource = ChartDataSource(this: self)
    private let miniChartView = MiniChartView()
    private lazy var miniChartDataSource: MiniChartDataSource = MiniChartDataSource(this: self)
    private var animator: ChartViewAnimator?
    private var chart: DrawingChart!

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

    public func display(chart: DrawingChart, animated: Bool) {
        chartView.dataSource = chartDataSource
        miniChartView.dataSource = miniChartDataSource
        self.chart = chart
        if let prevChart = self.chart, animated {
            animatedDisplay(chart: chart, prevChart: prevChart)
        } else {
            reloadData()
        }
    }

    @objc
    private func handleValueChanged() {
        guard let chart = self.chart else {
            return
        }
        let newChart = chart.changeSelectedTimeRange(miniChartView.selectedTimeRange)
        self.chart = newChart
        reloadData()
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: newChart.selectedTimeRange)
    }

    private func reloadData() {
        chartView.reloadData()
        miniChartView.reloadData()
    }

    private func animatedDisplay(chart: DrawingChart, prevChart: DrawingChart) {
//        let startValue = ChartViewAnimator.Value(valueRange: prevChart.valueRange, alpha: 1)
//        let endValue = ChartViewAnimator.Value(valueRange: chart.valueRange, alpha: 1)
//        let animator = ChartViewAnimator(animationDuration: 0.3, startValue: startValue, endValue: endValue)
//        animator.callback = { (finished, value) in
//            self.reloadData()
//            if finished {
//                self.animator = nil
//            }
//        }
//        self.animator = animator
//        animator.startAnimation()
    }

    private class MiniChartDataSource: ChartViewDataSource {
        unowned let this: ChartTableViewCell

        init(this: ChartTableViewCell) {
            self.this = this
        }

        func numberOfPlots(chartView: ChartViewProtocol) -> Int {
            return this.chart.plots.count
        }

        func chartView(_ chartView: ChartViewProtocol, plotDataAt idx: Int) -> (plot: Chart.Plot, alpha: CGFloat) {
            return (this.chart.plots[idx], 1)
        }

        func timestamps(chartView: ChartViewProtocol) -> [Int64] {
            return this.chart.timestamps
        }

        func indexRange(chartView: ChartViewProtocol) -> TimeIndexRange {
            return TimeIndexRange(length: this.chart.timestamps.count)
        }

        func timeRange(chartView: ChartViewProtocol) -> TimeRange {
            return this.chart.timeRange
        }

        func selectedTimeRange(chartView: ChartViewProtocol) -> TimeRange {
            return this.chart.selectedTimeRange
        }

        func valueRange(chartView: ChartViewProtocol) -> ValueRange {
            return this.chart.valueRange
        }
    }

    private class ChartDataSource: ChartViewDataSource {
        unowned let this: ChartTableViewCell

        init(this: ChartTableViewCell) {
            self.this = this
        }

        func numberOfPlots(chartView: ChartViewProtocol) -> Int {
            return this.chart.plots.count
        }

        func chartView(_ chartView: ChartViewProtocol, plotDataAt idx: Int) -> (plot: Chart.Plot, alpha: CGFloat) {
            return (this.chart.plots[idx], 1)
        }

        func timestamps(chartView: ChartViewProtocol) -> [Int64] {
            return this.chart.timestamps
        }

        func indexRange(chartView: ChartViewProtocol) -> TimeIndexRange {
            return this.chart.timeIndexRange
        }

        func timeRange(chartView: ChartViewProtocol) -> TimeRange {
            return this.chart.timeRange
        }

        func selectedTimeRange(chartView: ChartViewProtocol) -> TimeRange {
            return this.chart.selectedTimeRange
        }

        func valueRange(chartView: ChartViewProtocol) -> ValueRange {
            return this.chart.selectedValueRange
        }
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
