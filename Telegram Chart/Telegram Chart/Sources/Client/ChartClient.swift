//
// Created by Vadim on 2019-03-11.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartClient {

    public init() {
    }

    public func loadChartData() throws -> [Chart] {
        guard let dataDir = Bundle.main.url(forResource: "sample_data", withExtension: nil) else {
            throw ChartClientError.noData
        }
        var charts = [Chart]()
        for i in 1...5 {
            let typePath = dataDir.appendingPathComponent("\(i)", isDirectory: true)
            let overviewPath = typePath.appendingPathComponent("overview.json")
            guard let data = try? Data(contentsOf: overviewPath) else {
                throw ChartClientError.noData
            }
            let parser = ChartJsonParser()
            let chartTo = try parser.parseChartData(data)
            charts.append(try chartFromChartTO(chartTo))
        }
        return charts
    }
    
    // TODO: validate
    private func chartFromChartTO(_ chartTO: ChartTO) throws -> Chart {
        var columns = [String: [Int64]]()
        guard let size = chartTO.columns.first?.values.count else {
            throw ChartClientError.invalidData
        }
        for column in chartTO.columns {
            guard column.values.count == size else {
                throw ChartClientError.invalidData
            }
            columns[column.key] = column.values
        }
        try validateColumns(chartTO.columns, columns)

        let timestamps = try timestampsFromColumns(columns, chartTO)

        var plots = [Chart.Plot]()
        for column in chartTO.columns {
            let key = column.key
            if chartTO.types.values[key] == ChartTO.ColumnType.x {
                continue
            }
            let columnType = chartTO.types.values[key]!
            let plotType: PlotType
            switch columnType {
            case .line:
                plotType = .line
            case .x:
                fatalError("Illegal!")
                break
            case .area:
                plotType = .area
            case .bar:
                plotType = .bar
            }
            let plot = try plotWithKey(key, chartTO: chartTO, values: column.values, type: plotType)
            plots.append(plot)
        }

        return Chart(timestamps: timestamps, plots: plots, yScaled: chartTO.yScaled)
    }

    private func plotWithKey(_ key: String, chartTO: ChartTO, values: [Int64], type: PlotType) throws -> Chart.Plot {
        guard let name = chartTO.names.values[key],
              let colorCode = chartTO.colors.values[key] else {
            throw ChartClientError.invalidData
        }
        let color = colorWithCode(colorCode)
        let plot = Chart.Plot(identifier: key, name: name, color: color, values: values, type: type)
        return plot
    }

    private func colorWithCode(_ code: String) -> UIColor {
        let scanner = Scanner(string: code)
        if (code.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1)
    }

    private func timestampsFromColumns(_ columns: [String: [Int64]], _ chartTO: ChartTO) throws -> [Int64] {
        var timestamps: [Int64]? = nil
        for (key, values) in columns {
            guard let columnType = chartTO.types.values[key] else {
                throw ChartClientError.invalidData
            }
            switch columnType {
            case .x:
                guard timestamps == nil else {
                    throw ChartClientError.invalidData
                }
                timestamps = values
            default:
                   break
            }
        }
        guard let ts = timestamps, ts.count > 1 else {
            throw ChartClientError.invalidData
        }
        return timestamps!
    }

    private func validateColumns(_ columnsTO: [ChartTO.Column], _ columns: [String: [Int64]]) throws {
        guard columnsTO.count == columns.count else {
            throw ChartClientError.invalidData
        }
    }
}

public enum ChartClientError: Error {
    case noData
    case invalidData
}
