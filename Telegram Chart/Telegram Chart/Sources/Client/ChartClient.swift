//
// Created by Vadim on 2019-03-11.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartClient {

    public init() {
    }

    public func loadChartData() throws -> ChartTO {
        guard let url = Bundle.main.url(forResource: "sample_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw ChartClientError.noData
        }
        let parser = ChartJsonParser()
        return try parser.parseData(data)
    }
}

public enum ChartClientError: Error {
    case noData
}
