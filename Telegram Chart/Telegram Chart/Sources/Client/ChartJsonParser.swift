//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation


// TODO: add data check
public final class ChartJsonParser {

    public init() {
    }

    public func parseData(_ data: Data) throws -> ChartTO {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ChartParserError.noJson
        }
        guard let remoteCharts = json as? [Any] else {
            throw ChartParserError.noChart
        }
        let charts = try remoteCharts.map { return try readChart($0) }
        return ChartTO(charts: charts)
    }

    private func readChart(_ remoteChart0: Any) throws -> ChartTO.Chart {
        guard let remoteChart = remoteChart0 as? [String: Any] else {
            throw ChartParserError.noChart
        }
        let columns = try readColumns(remoteChart["columns"])
        let columnKeys = columns.map{ $0.key }
        let types = try readTypes(remoteChart["types"], columnKeys: columnKeys)
        guard types.values.count > 1 else {
            throw ChartParserError.noChart
        }
        let names = try readNames(remoteChart["names"])
        let colors = try readColors(remoteChart["colors"])
        return ChartTO.Chart(columns: columns, types: types, names: names, colors: colors)
    }

    private func readColors(_ remoteColors: Any?) throws -> ChartTO.Chart.Colors {
        return try ChartTO.Chart.Colors(values: readValues(remoteColors))
    }

    private func readNames(_ remoteNames: Any?) throws -> ChartTO.Chart.Names {
        return try ChartTO.Chart.Names(values: readValues(remoteNames))
    }

    private func readTypes(_ remoteTypes0: Any?, columnKeys: [String]) throws -> ChartTO.Chart.Types {
        let remoteTypes = try readValues(remoteTypes0)
        var types = [ChartTO.Chart.ColumnKey: ChartTO.Chart.ColumnType]()
        for key in columnKeys {
            guard let type = remoteTypes[key] else {
                continue
            }
            switch type {
            case ChartTO.Chart.ColumnType.x.rawValue:
                types[key] = .x
            case ChartTO.Chart.ColumnType.line.rawValue:
                types[key] = .line
            default:
                continue
            }
        }
        return ChartTO.Chart.Types(values: types)
    }

    private func readValues(_ remotes0: Any?) throws -> [ChartTO.Chart.ColumnKey: String] {
        guard let remotes = remotes0 as? [String: String] else {
            throw ChartParserError.noChart
        }
        return remotes
    }

    private func readColumns(_ remoteColumns0: Any?) throws -> [ChartTO.Chart.Column] {
        guard let remoteColumns = remoteColumns0 as? [[Any]] else {
            throw ChartParserError.noChart
        }
        return try remoteColumns.map { try readColumn($0) }
    }

    private func readColumn(_ remoteColumn: [Any]) throws -> ChartTO.Chart.Column {
        guard let key = remoteColumn.first as? String else {
            throw ChartParserError.noChart
        }
        var values = [Int64]()
        for i in 1..<remoteColumn.count {
            guard let val = remoteColumn[i] as? Int64 else {
                throw ChartParserError.noChart
            }
            values.append(val)
        }
        return ChartTO.Chart.Column(key: key, values: values)
    }
}

public enum ChartParserError: Error {
    case noJson
    case noChart
}
