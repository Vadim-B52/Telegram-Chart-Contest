//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation


// TODO: add data check
public final class ChartClient {

    public init() {
    }

    public func loadChartData() throws -> ChartTransferObject {
        guard let url = Bundle.main.url(forResource: "sample_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw ChartClientError.noData
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ChartClientError.noJson
        }
        guard let remoteCharts = json as? [Any] else {
            throw ChartClientError.noChart
        }
        let charts = try remoteCharts.map { return try readChart($0) }
        return ChartTransferObject(charts: charts)
    }

    private func readChart(_ remoteChart0: Any) throws -> ChartTransferObject.Chart {
        guard let remoteChart = remoteChart0 as? [String: Any] else {
            throw ChartClientError.noChart
        }
        let columns = try readColumns(remoteChart["columns"])
        let columnKeys = columns.map{ $0.key }
        let types = try readTypes(remoteChart["types"], columnKeys: columnKeys)
        guard types.values.count > 1 else {
            throw ChartClientError.noChart
        }
        let names = try readNames(remoteChart["names"])
        let colors = try readColors(remoteChart["colors"])
        return ChartTransferObject.Chart(columns: columns, types: types, names: names, colors: colors)
    }

    private func readColors(_ remoteColors: Any?) throws -> ChartTransferObject.Chart.Colors {
        return try ChartTransferObject.Chart.Colors(values: readValues(remoteColors))
    }

    private func readNames(_ remoteNames: Any?) throws -> ChartTransferObject.Chart.Names {
        return try ChartTransferObject.Chart.Names(values: readValues(remoteNames))
    }

    private func readTypes(_ remoteTypes0: Any?, columnKeys: [String]) throws -> ChartTransferObject.Chart.Types {
        let remoteTypes = try readValues(remoteTypes0)
        var types = [ChartTransferObject.Chart.ColumnKey: ChartTransferObject.Chart.ColumnType]()
        for key in columnKeys {
            guard let type = remoteTypes[key] else {
                continue
            }
            switch type {
            case ChartTransferObject.Chart.ColumnType.x.rawValue:
                types[key] = .x
            case ChartTransferObject.Chart.ColumnType.line.rawValue:
                types[key] = .line
            default:
                continue
            }
        }
        return ChartTransferObject.Chart.Types(values: types)
    }

    private func readValues(_ remotes0: Any?) throws -> [ChartTransferObject.Chart.ColumnKey: String] {
        guard let remotes = remotes0 as? [String: String] else {
            throw ChartClientError.noChart
        }
        return remotes
    }

    private func readColumns(_ remoteColumns0: Any?) throws -> [ChartTransferObject.Chart.Column] {
        guard let remoteColumns = remoteColumns0 as? [[Any]] else {
            throw ChartClientError.noChart
        }
        return try remoteColumns.map { try readColumn($0) }
    }

    private func readColumn(_ remoteColumn: [Any]) throws -> ChartTransferObject.Chart.Column {
        guard let key = remoteColumn.first as? String else {
            throw ChartClientError.noChart
        }
        var values = [Int64]()
        for i in 1..<remoteColumn.count {
            guard let val = remoteColumn[i] as? Int64 else {
                throw ChartClientError.noChart
            }
            values.append(val)
        }
        return ChartTransferObject.Chart.Column(key: key, values: values)
    }
}

public enum ChartClientError: Error {
    case noData
    case noJson
    case noChart
}
