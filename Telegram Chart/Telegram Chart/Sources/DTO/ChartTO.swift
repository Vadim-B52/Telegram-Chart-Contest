//
//  ChartServerResponse.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

// TODO: naming
// TODO: optionals ?

public struct ChartTO {
    public let columns: [Column]
    public let types: Types
    public let names: Names
    public let colors: Colors
    public let yScaled: Bool

    public typealias ColumnKey = String

    public enum ColumnType: String, RawRepresentable {
        case x = "x"
        case line = "line"
        case area = "area"
        case bar = "bar"
    }

    public struct Column {
        public let key: ColumnKey
        public let values: [Int64]
    }

    public struct Types {
        public let values: [ColumnKey: ColumnType]
    }

    public struct Names {
        public let values: [ColumnKey: String]
    }

    public struct Colors {
        public let values: [ColumnKey: String]
    }
}
