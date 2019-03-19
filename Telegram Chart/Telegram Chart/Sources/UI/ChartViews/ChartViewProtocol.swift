//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartViewProtocol {
    var dataSource: ChartViewDataSource? { get }
    func reloadData()
}

public protocol ChartViewDataSource: AnyObject {
    func numberOfPlots(chartView: ChartViewProtocol) -> Int
    func chartView(_ chartView: ChartViewProtocol, plotDataAt idx: Int) -> (plot: Chart.Plot, alpha: CGFloat)
    func timestamps(chartView: ChartViewProtocol) -> [Int64]
    func indexRange(chartView: ChartViewProtocol) -> TimeIndexRange
    func timeRange(chartView: ChartViewProtocol) -> TimeRange
    func selectedTimeRange(chartView: ChartViewProtocol) -> TimeRange
    func valueRange(chartView: ChartViewProtocol) -> ValueRange
}
