//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartViewColorSource: AnyObject {
    func colorToUseForAdjusting(chartView: ChartView) -> UIColor?
}

public class ChartView: UIControl, ChartViewProtocol {

    private var layers = [CAShapeLayer]()
    private var chart: DrawingChart?
    private var colorToUseForAdjusting: UIColor!

    public var lineWidth: CGFloat = 1
    public weak var colorSource: ChartViewColorSource?

    public var chartInsets = UIEdgeInsets.zero {
        didSet {
            redraw(animation: .none)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true // TODO: improve?
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clipsToBounds = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let frame = plotFrame()
        for l in layers {
            l.frame = frame
        }
        redraw(animation: .none)
    }

    public func displayChart(_ chart: DrawingChart?, animation: ChartViewAnimation) {
        if chart == nil {
            layer.backgroundColor = nil
        }
        colorToUseForAdjusting = colorSource?.colorToUseForAdjusting(chartView: self) ?? UIColor.white
        self.chart = chart
        updateLayers()
        redraw(animation: animation)
    }

    private func updateLayers() {
        let plotsCount = chart?.allPlots.count ?? 0
        let d = layers.count - plotsCount
        if d > 0 {
            for _ in 0..<d {
                layers.removeLast().removeFromSuperlayer()
            }
        } else if d < 0 {
            let frame = plotFrame()
            for _ in 0..<(-d) {
                let plotLayer = CAShapeLayer()
                plotLayer.frame = frame
                layer.insertSublayer(plotLayer, at: 0)
                layers.append(plotLayer)
            }
        }
    }

    private func plotFrame() -> CGRect {
        return layer.bounds
    }

    private func redraw(animation: ChartViewAnimation) {
        guard let chart = chart else {
            return
        }

        for (idx, plot) in chart.allPlots.enumerated().reversed() {
            let plotLayer = layers[idx]
            let panel = makeChartPanel(chart: chart, plot: plot)
            panel.drawInLayer(plotLayer, rect: plotLayer.bounds.inset(by: chartInsets), animation: animation)
        }
    }

    // TODO: type dispatch vs case
    private func makeChartPanel(chart: DrawingChart, plot: Chart.Plot) -> ChartPanel {
        var chartPanel: ChartPanel
        switch plot.type {
        case .line:
            chartPanel = LineChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        case .area:
            chartPanel = PercentageStackedAreaChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        case .bar:
//          TODO: bar chart drawer if needed
            chartPanel = StackedBarChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        }
        chartPanel.delegate = self
        return chartPanel
    }
}

extension ChartView: ChartPanelDelegate {
    public func charPanel(_ panel: ChartPanel, applyPath path: CGPath, isVisible: Bool, toLayer layer: CAShapeLayer, animation: ChartViewAnimation) {
        layer.path = path
        layer.opacity = isVisible ? 1 : 0
        if animation != .none {
            let animationGroup = CAAnimationGroup()
            let pathAnimation = CABasicAnimation(keyPath: "path")
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            animationGroup.animations = [pathAnimation, opacityAnimation]
            animationGroup.duration = Animations.duration
            if animation == .linear {
                animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            } else {
                animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            }

            pathAnimation.fromValue = layer.presentation()?.path ?? layer.path
            pathAnimation.toValue = path

            opacityAnimation.fromValue = layer.presentation()?.opacity ?? layer.opacity
            opacityAnimation.toValue = isVisible ? 1 : 0

            layer.add(animationGroup, forKey: "opacityAndPathAnimationKey")
        }
    }

    public func charPanel(_ panel: ChartPanel, applyBackgroundColor color: UIColor, toSuperlayerAnimated a: ChartViewAnimation) {
        layer.backgroundColor = color.cgColor
        if a != .none {
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.duration = Animations.duration
            if a == .linear {
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            } else {
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            }
            animation.fromValue = layer.presentation()?.backgroundColor ?? layer.backgroundColor
            animation.toValue = color.cgColor
            layer.add(animation, forKey: "backgroundColorAnimationKey")
        }
    }

    public func colorToUseForAdjusting(chartPanel: ChartPanel) -> UIColor {
        return colorToUseForAdjusting
    }
}
