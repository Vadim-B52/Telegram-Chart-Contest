//
//  ChartServerResponse.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartTO: NSObject {
    public let charts: [Chart]?
    
    public init(charts: [Chart]?) {
        self.charts = charts
    }

    // TODO: optionals ?
    public class Chart: NSObject {
        public let columns: [Column]
        public let types: Types
        public let names: Names
        public let colors: Colors

        public init(columns: [Column], types: Types, names: Names, colors: Colors) {
            self.columns = columns
            self.types = types
            self.names = names
            self.colors = colors
        }

        public typealias ColumnKey = String

        public enum ColumnType: String, RawRepresentable {
            case x = "x"
            case line = "line"
        }

        public class Column: NSObject {
            public let key: ColumnKey
            public let values: [Int64]

            public init(key: String, values: [Int64]) {
                self.key = key
                self.values = values
            }
        }
        
        public class Types: NSObject {
            public let values: [ColumnKey: ColumnType]

            public init(values: [ColumnKey: ColumnType]) {
                self.values = values
            }
        }
        
        public class Names: NSObject {
            public let values: [ColumnKey: String]

            public init(values: [ColumnKey: String]) {
                self.values = values
            }
        }
        
        public class Colors: NSObject {
            public let values: [ColumnKey: String]

            public init(values: [ColumnKey: String]) {
                self.values = values
            }
        }
    }
}
