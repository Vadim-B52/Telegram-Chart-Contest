//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIControl, ChartViewProtocol {

    private var layers = [CAShapeLayer]()

    public var chart: DrawingChart? {
        didSet {
            layers.forEach { $0.removeFromSuperlayer() }
            layers.removeAll()
            redraw()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layers.forEach { $0.removeFromSuperlayer() }
        redraw()
    }

    private func redraw() {
        guard let chart = chart else {
            return
        }
        let drawingRect = layer.bounds.inset(by: UIEdgeInsets(top: 11, left: 0, bottom: 9, right: 0))
        chart.plots.forEach { plot in
            let plotLayer = CAShapeLayer()
            self.layer.addSublayer(plotLayer)
            plotLayer.frame = drawingRect
            let panel = ChartPanel(
                    timestamps: chart.timestamps,
                    indexRange: chart.indexRange,
                    timeRange: chart.timeRange,
                    valueRange: chart.valueRange,
                    plot: plot,
                    lineWidth: 1)

            panel.drawInContext(plotLayer, rect: plotLayer.bounds)
            layers.append(plotLayer)
        }
    }
}
