//
//  ChartServerResponse.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartList: NSObject {
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

        public class Column: NSObject {
            public let type: String?
            public let values: [Int64]?

            public init(type: String?, values: [Int64]?) {
                self.type = type
                self.values = values
            }
        }
        
        public class Types: NSObject {
            public let y0: String?
            public let y1: String?
            public let x: String?

            public init(y0: String?, y1: String?, x: String?) {
                self.y0 = y0
                self.y1 = y1
                self.x = x
            }
        }
        
        public class Names: NSObject {
            public let y0: String?
            public let y1: String?

            public init(y0: String?, y1: String?) {
                self.y0 = y0
                self.y1 = y1
            }
        }
        
        public class Colors: NSObject {
            public let y0: String?
            public let y1: String?

            public init(y0: String?, y1: String?) {
                self.y0 = y0
                self.y1 = y1
            }
        }
    }
}
