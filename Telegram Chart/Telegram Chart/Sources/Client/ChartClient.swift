//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation


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
        guard let remoteCharts =
    }
}


public enum ChartClientError: Error {
    case noData
    case noJson
    case noChart
}
