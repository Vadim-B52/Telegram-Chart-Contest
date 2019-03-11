//
// Created by Vadim on 2019-03-11.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartClient {

    public init() {
    }

    public func loadChartData() throws -> [Chart] {
        guard let url = Bundle.main.url(forResource: "sample_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw ChartClientError.noData
        }
        let parser = ChartJsonParser()
        let chartTO = try parser.parseData(data)
        return try chartTO.charts.map { try chartFromChartTO($0) }
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
        for (key, values) in columns {
            let columnType = chartTO.types.values[key]!
            switch columnType {
            case .line:
                let plot = try linePlotWithKey(key, chartTO: chartTO, timestamps: timestamps, values: values)
                plots.append(plot)
            default:
                break
            }
        }

        return Chart(plots: plots)
    }

    private func linePlotWithKey(_ key: String, chartTO: ChartTO, timestamps: [Int64], values: [Int64]) throws -> Chart.Plot {
        guard let name = chartTO.names.values[key],
              let colorCode = chartTO.colors.values[key] else {
            throw ChartClientError.invalidData
        }
        let color = colorWithCode(colorCode)
        let plot = Chart.LinePlot(name: name, color: color, timestamps: timestamps, values: values)
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
        guard timestamps != nil else {
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
