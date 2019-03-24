//
// Created by Vadim on 2019-03-20.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartViewContainer<ChartViewType: UIView & ChartViewProtocol>: UIView, CAAnimationDelegate {

    private let chartView1: ChartViewType
    private let chartView2: ChartViewType
    private var chart: DrawingChart?
    private var transitionProgress: Float = 0
    private var transitionState: TransitionState<ChartViewType>? {
        didSet {
            if let oldValue = oldValue {
                oldValue.displayLink.invalidate()
            }
        }
    }

    public var chartViews: [ChartViewType] { return [chartView1, chartView2] }

    public init(_ factory: @autoclosure () -> ChartViewType) {
        chartView1 = factory()
        chartView2 = factory()
        super.init(frame: .zero)

        chartView1.backgroundColor = .clear
        chartView1.frame = .zero
        chartView1.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(chartView1)

        chartView2.backgroundColor = .clear
        chartView2.frame = .zero
        chartView2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(chartView2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func displayChart(_ chart0: DrawingChart?, animated: Bool = false) {
        defer {
            self.chart = chart0
        }
        guard animated, transitionState == nil, let chart = chart0, let prevChart = self.chart else {
            performDeadTransitionToChart(chart0)
            return
        }
        performAnimatedTransitionToChart(chart, previousChart: prevChart)
    }

    private func performDeadTransitionToChart(_ chart: DrawingChart?) {
        transitionState = nil
        chartView1.chart = chart
        chartView2.chart = nil
        chartView1.layer.opacity = 1
        chartView2.layer.opacity = 0
        chartView1.layer.removeAllAnimations()
        chartView2.layer.removeAllAnimations()
    }

    private func performAnimatedTransitionToChart(_ chart: DrawingChart, previousChart: DrawingChart) {
        chartView1.chart = previousChart
        chartView2.chart = previousChart
        chartView1.layer.opacity = 1
        chartView2.layer.opacity = 1

        let link = CADisplayLink(target: self, selector: #selector(onRenderTime))
        link.add(to: .main, forMode: .common)

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.4
        animation.delegate = self

        let toShowPlot = previousChart.plots.count < chart.plots.count
        if toShowPlot {
            chartView2.layer.opacity = 1
            animation.fromValue = 0
            animation.toValue = 1
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            transitionState = TransitionState(
                    displayLink: link,
                    formula: { $0 },
                    beginChart: previousChart,
                    endChart: chart,
                    beginChartReceiver: chartView1,
                    endChartReceiver: chartView2)
        } else {
            chartView2.layer.opacity = 0
            animation.fromValue = 1
            animation.toValue = 0
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transitionState = TransitionState(
                    displayLink: link,
                    formula: { 1 - $0 },
                    beginChart: previousChart,
                    endChart: chart,
                    beginChartReceiver: chartView2,
                    endChartReceiver: chartView1)
        }
        chartView2.layer.add(animation, forKey: "opacityAnimation")
    }

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let state = transitionState else {
            return
        }
        transitionState = nil
        state.endChartReceiver.chart = chart
        state.beginChartReceiver.chart = nil
        state.endChartReceiver.layer.opacity = 1
        state.beginChartReceiver.layer.opacity = 0
    }

    @objc
    private func onRenderTime() {
        guard let state = transitionState, let opacity = chartView2.layer.presentation()?.opacity else {
            return
        }
        transitionProgress = state.formula(opacity)

        let minD = state.endChart.valueRange.min - state.beginChart.valueRange.min
        let maxD = state.endChart.valueRange.max - state.beginChart.valueRange.max
        let valueRange = ValueRange(
                min: state.beginChart.valueRange.min + Chart.Value(transitionProgress * Float(minD)),
                max: state.beginChart.valueRange.max + Chart.Value(transitionProgress * Float(maxD)))

        state.beginChartReceiver.chart = DrawingChart(
                plots: state.beginChart.plots,
                timestamps: state.beginChart.timestamps,
                timeRange: state.beginChart.timeRange,
                selectedTimeRange: state.beginChart.selectedTimeRange,
                valueRangeCalculation: StaticValueRangeCalculation(valueRange: valueRange),
                yAxisCalculation: ValueRangeHasStaticYAxis(valueRange: valueRange, yAxisValues: state.beginChart.axisValues))

        state.endChartReceiver.chart = DrawingChart(
                plots: state.endChart.plots,
                timestamps: state.endChart.timestamps,
                timeRange: state.endChart.timeRange,
                selectedTimeRange: state.endChart.selectedTimeRange,
                valueRangeCalculation: StaticValueRangeCalculation(valueRange: valueRange),
                yAxisCalculation: ValueRangeHasStaticYAxis(valueRange: valueRange, yAxisValues: state.endChart.axisValues))
    }
}

extension ChartViewContainer: ChartViewAnimationProgressDataSource {
    public func animationProgressAlpha(chartView: ChartViewProtocol) -> CGFloat? {
        guard let state = transitionState else {
            return nil
        }
        if chartView as! ChartViewType == state.beginChartReceiver {
            return CGFloat(1 - transitionProgress)
        }
        return CGFloat(transitionProgress)
    }
}

fileprivate extension ChartViewContainer {
    private struct TransitionState<T> {
        let displayLink: CADisplayLink
        let formula: ((Float) -> Float)
        let beginChart: DrawingChart
        let endChart: DrawingChart
        let beginChartReceiver: T
        let endChartReceiver: T
    }
}
