//
//  Cells.swift
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
    private var chart: DrawingChart?

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
        if let prevChart = self.chart, animated {
            animatedDisplay(chart: chart, prevChart: prevChart)
        } else {
            deadDisplay(chart: chart)
        }
        self.chart = chart
    }

    @objc
    private func handleValueChanged() {
        guard let chart = chartView.chart else {
            return
        }
        let newChart = chart.changeSelectedTimeRange(miniChartView.selectedTimeRange)
        chartView.chart = newChart
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: chart.selectedTimeRange)
    }

    private func deadDisplay(chart: DrawingChart) {
        chartView.chart = chart
        miniChartView.chart = DrawingChart(timestamps: chart.timestamps, timeRange: chart.timeRange, plots: chart.plots)
        miniChartView.selectedTimeRange = chart.timeRange
    }

    private var animator: ChartViewAnimator!
    private func animatedDisplay(chart: DrawingChart, prevChart: DrawingChart) {
        let startValue = ChartViewAnimator.Value(valueRange: prevChart.valueRange, alpha: 1)
        let endValue = ChartViewAnimator.Value(valueRange: chart.valueRange, alpha: 1)
        let animator = ChartViewAnimator(animationDuration: 0.3, startValue: startValue, endValue: endValue)
        animator.callback = { (finished, value) in
            let c = DrawingChart(
                    timestamps: chart.timestamps,
                    timeRange: chart.timeRange,
                    valueRange: value.valueRange,
                    plots: chart.plots)

            self.deadDisplay(chart: c)
            if finished {
                self.animator = nil
            }
        }
        self.animator = animator
        animator.startAnimation()
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

public class NightModeTableViewCell: UITableViewCell {
    public private(set) lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        return button
    }()
}
