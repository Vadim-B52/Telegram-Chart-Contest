//
//  ChartServerResponse.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartTransferObject: NSObject {
    public let charts: [Chart]?
    
    public init(charts: [Chart]?) {
        self.charts = charts
    }
    
    public class Chart: NSObject {
        public let columns: [Column]?
        public let types: Types?
        public let names: Names?
        public let colors: Colors?

        public init(columns: [Column]?, types: Types?, names: Names?, colors: Colors?) {
            self.columns = columns
            self.types = types
            self.names = names
            self.colors = colors
        }

        public typealias ColumnType = String

        public class Column: NSObject {
            public let type: ColumnType?
            public let values: [Int64]?

            public init(type: String?, values: [Int64]?) {
                self.type = type
                self.values = values
            }
        }
        
        public class Types: NSObject {
            public let values: [ColumnType: String]?

            public init(values: [ColumnType: String]?) {
                self.values = values
            }
        }
        
        public class Names: NSObject {
            public let values: [ColumnType: String]?

            public init(values: [ColumnType: String]?) {
                self.values = values
            }
        }
        
        public class Colors: NSObject {
            public let values: [ColumnType: String]?

            public init(values: [ColumnType: String]?) {
                self.values = values
            }
        }
    }
}
