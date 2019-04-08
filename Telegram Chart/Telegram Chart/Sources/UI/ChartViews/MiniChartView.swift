//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIControl, ChartViewProtocol {

    private var layers = [CAShapeLayer]()

    public var chart: DrawingChart? {
        didSet {
            updateLayers()
            redraw()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let frame = plotFrame()
        layers.forEach { $0.frame = frame }
        redraw()
    }

    private func updateLayers() {
        let plotsCount = chart?.allPlots.count ?? 0
        let d = layers.count - plotsCount
        if d > 0 {
            for _ in 0..<d {
                layers.last?.removeFromSuperlayer()
            }
        } else if d < 0 {
            let frame = plotFrame()
            for _ in 0..<(-d) {
                let plotLayer = CAShapeLayer()
                plotLayer.frame = frame
                layer.addSublayer(plotLayer)
                layers.append(plotLayer)
            }
        }
    }

    private func plotFrame() -> CGRect {
        return layer.bounds
    }

    private func redraw() {
        guard let chart = chart else {
            return
        }

        for (idx, plot) in chart.allPlots.enumerated() {
            let plotLayer = layers[idx]
            let panel = ChartPanel(
                    timestamps: chart.timestamps,
                    indexRange: chart.indexRange,
                    timeRange: chart.timeRange,
                    valueRange: chart.valueRange,
                    plot: plot,
                    lineWidth: 1)

            panel.drawInContext(plotLayer, rect: plotLayer.bounds)
            plotLayer.opacity = chart.isPlotVisible(plot) ? 1 : 0
        }
    }
}
