//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation


// TODO: add data check
public final class ChartJsonParser {

    public init() {
    }

    public func parseChartListData(_ data: Data) throws -> [ChartTO] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ChartParserError.noJson
        }
        guard let remoteCharts = json as? [Any] else {
            throw ChartParserError.noChart
        }
        return try remoteCharts.map { return try readChart($0) }
    }
    
    public func parseChartData(_ data: Data) throws -> ChartTO {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ChartParserError.noJson
        }
        return try readChart(json)
    }

    private func readChart(_ remoteChart0: Any) throws -> ChartTO {
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
        let yScaled = remoteChart["y_scaled"] as? Bool ?? false
        return ChartTO(columns: columns, types: types, names: names, colors: colors, yScaled: yScaled)
    }

    private func readColors(_ remoteColors: Any?) throws -> ChartTO.Colors {
        return try ChartTO.Colors(values: readValues(remoteColors))
    }

    private func readNames(_ remoteNames: Any?) throws -> ChartTO.Names {
        return try ChartTO.Names(values: readValues(remoteNames))
    }

    private func readTypes(_ remoteTypes0: Any?, columnKeys: [String]) throws -> ChartTO.Types {
        let remoteTypes = try readValues(remoteTypes0)
        var types = [ChartTO.ColumnKey: ChartTO.ColumnType]()
        for key in columnKeys {
            guard let type = remoteTypes[key] else {
                continue
            }
            switch type {
            case ChartTO.ColumnType.x.rawValue:
                types[key] = .x
            case ChartTO.ColumnType.line.rawValue:
                types[key] = .line
            case ChartTO.ColumnType.bar.rawValue:
                types[key] = .bar
            case ChartTO.ColumnType.area.rawValue:
                types[key] = .area
            default:
                assertionFailure("need be implementer")
                continue
            }
        }
        return ChartTO.Types(values: types)
    }

    private func readValues(_ remotes0: Any?) throws -> [ChartTO.ColumnKey: String] {
        guard let remotes = remotes0 as? [String: String] else {
            throw ChartParserError.noChart
        }
        return remotes
    }

    private func readColumns(_ remoteColumns0: Any?) throws -> [ChartTO.Column] {
        guard let remoteColumns = remoteColumns0 as? [[Any]] else {
            throw ChartParserError.noChart
        }
        return try remoteColumns.map { try readColumn($0) }
    }

    private func readColumn(_ remoteColumn: [Any]) throws -> ChartTO.Column {
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
        return ChartTO.Column(key: key, values: values)
    }
}

public enum ChartParserError: Error {
    case noJson
    case noChart
}
